#!/usr/bin/env python3
"""
Regenerates sources.txt from Deadboy666/SteamTracking's ClientManifest,
cycling the previous "latest" into "stable" whenever the build actually
changed. Manual/on-demand (not a blind auto-committer) -- run it, review
the diff, then commit/push and re-run sync-mirror.sh to populate the VPS.

Layout:
  sources.txt         -- current "latest" package list (unchanged format:
                          flat list of Fastly URLs, one per line)
  client_version.txt  -- the client build number sources.txt is pinned to
  stable-sources.txt   -- the "stable" package list (one cycle behind)
  stable_version.txt  -- the client build number stable-sources.txt is
                          pinned to

On each run:
  1. Fetch the manifest, parse its "version" and every package's "file"
     (+ "zipvz" if present).
  2. If the fetched version matches client_version.txt, nothing to do.
  3. Otherwise: sources.txt -> stable-sources.txt, client_version.txt ->
     stable_version.txt (latest cycles to stable), then sources.txt and
     client_version.txt are rewritten from the freshly fetched manifest.

Usage: python3 update-sources.py [--manifest-url URL] [--dry-run]
"""

import argparse
import sys
import urllib.request
from pathlib import Path

DEFAULT_MANIFEST_URL = (
	"https://raw.githubusercontent.com/Deadboy666/SteamTracking/"
	"refs/heads/headcrab/ClientManifest/steam_client_ubuntu12"
)
BASE_URL = "https://client-update.fastly.steamstatic.com/"

REPO_ROOT = Path(__file__).resolve().parent
SOURCES = REPO_ROOT / "sources.txt"
STABLE_SOURCES = REPO_ROOT / "stable-sources.txt"
VERSION = REPO_ROOT / "client_version.txt"
STABLE_VERSION = REPO_ROOT / "stable_version.txt"


def tokenize(text: str):
	# Minimal VDF tokenizer: quoted strings and brace punctuation. Steam's
	# ClientManifest files are plain VDF with no escape sequences, comments,
	# or macro directives to worry about -- this only needs to handle
	# what's actually in them.
	i = 0
	n = len(text)
	while i < n:
		c = text[i]
		if c in " \t\r\n":
			i += 1
			continue
		if c == "{" or c == "}":
			yield c
			i += 1
			continue
		if c == '"':
			j = i + 1
			while j < n and text[j] != '"':
				j += 1
			yield text[i + 1:j]
			i = j + 1
			continue
		# Anything else (shouldn't occur in these files) -- skip the char
		# rather than looping forever on unexpected input.
		i += 1


def parse_vdf(text: str) -> dict:
	tokens = list(tokenize(text))
	pos = 0

	def parse_block():
		nonlocal pos
		obj = {}
		while pos < len(tokens) and tokens[pos] != "}":
			key = tokens[pos]
			pos += 1
			if pos < len(tokens) and tokens[pos] == "{":
				pos += 1
				obj[key] = parse_block()
				pos += 1  # skip closing }
			else:
				value = tokens[pos]
				pos += 1
				obj[key] = value
		return obj

	# Top-level: a single "<name>" { ... } block.
	if pos < len(tokens):
		pos += 1  # skip the root name token
	if pos < len(tokens) and tokens[pos] == "{":
		pos += 1
		root = parse_block()
	else:
		root = {}
	return root


def fetch_manifest(url: str) -> str:
	with urllib.request.urlopen(url, timeout=30) as resp:
		return resp.read().decode("utf-8")


def extract_urls_and_version(manifest: dict) -> tuple[list[str], str]:
	version = manifest.get("version", "")
	urls = []
	for key, val in manifest.items():
		if key == "version" or not isinstance(val, dict):
			continue
		if "file" in val:
			urls.append(BASE_URL + val["file"])
		if "zipvz" in val:
			urls.append(BASE_URL + val["zipvz"])
	return urls, version


def read_text(path: Path) -> str:
	return path.read_text(encoding="utf-8") if path.exists() else ""


def write_text_lf(path: Path, text: str) -> None:
	# Path.write_text() translates \n to the platform default on Windows
	# (CRLF) unless newline="" is forced -- keep these files LF-only like
	# sync-mirror.sh, regardless of what OS this runs on.
	with open(path, "w", encoding="utf-8", newline="\n") as f:
		f.write(text)


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--manifest-url", default=DEFAULT_MANIFEST_URL)
	ap.add_argument("--dry-run", action="store_true", help="Fetch and report, don't write any files")
	args = ap.parse_args()

	print(f"Fetching manifest: {args.manifest_url}")
	manifest_text = fetch_manifest(args.manifest_url)
	manifest = parse_vdf(manifest_text)
	urls, new_version = extract_urls_and_version(manifest)

	if not new_version or not urls:
		print("update-sources: failed to parse a version or any package URLs out of the manifest", file=sys.stderr)
		sys.exit(1)

	current_version = read_text(VERSION).strip()

	print(f"Current pinned version: {current_version or '(none)'}")
	print(f"Manifest version:       {new_version}")
	print(f"Packages found:         {len(urls)}")

	if new_version == current_version:
		print("update-sources: already up to date, nothing to do")
		return

	if args.dry_run:
		print("update-sources: --dry-run set, not writing anything")
		return

	# Cycle latest -> stable (only if we actually have a prior pinned
	# version -- first-ever run shouldn't produce an empty stable-sources.txt).
	if current_version:
		write_text_lf(STABLE_SOURCES, read_text(SOURCES))
		write_text_lf(STABLE_VERSION, current_version + "\n")
		print(f"Cycled previous latest ({current_version}) into stable-sources.txt")

	write_text_lf(SOURCES, "\n".join(urls) + "\n")
	write_text_lf(VERSION, new_version + "\n")
	print(f"Wrote sources.txt + client_version.txt for build {new_version}")
	print("Next: review the diff, commit/push, then run sync-mirror.sh against")
	print("both /srv/headcrab/client-latest and /srv/headcrab/client-stable.")


if __name__ == "__main__":
	main()
