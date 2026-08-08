#!/bin/bash
# Syncs the private Steam-client mirror (headcrab.bifrosthub.ru) against
# sources.txt. Run this on the VPS itself after sources.txt is repinned to
# a new client build -- it fetches only whatever files aren't already
# present (idempotent, safe to re-run), so the mirror never needs manual
# re-upload.
#
# Usage: ./sync-mirror.sh [sources.txt] [dest-dir]
#   sources.txt defaults to ./sources.txt
#   dest-dir defaults to /srv/headcrab/client
#
# To seed the client-testing mirror instead:
#   ./sync-mirror.sh sources.txt /srv/headcrab/client-testing

set -euo pipefail

SOURCES="${1:-sources.txt}"
DEST="${2:-/srv/headcrab/client}"

if [ ! -f "$SOURCES" ]; then
	echo "sync-mirror: $SOURCES not found" >&2
	exit 1
fi

mkdir -p "$DEST"

total=0
fetched=0
skipped=0
failed=0

while IFS= read -r url; do
	# sources.txt is tracked with CRLF line endings -- strip a trailing \r
	# so it doesn't end up baked into the URL/filename (wget silently
	# fails on a \r-terminated URL).
	url="${url%$'\r'}"
	[ -z "$url" ] && continue
	total=$((total + 1))

	fname=$(basename "$url")
	dest_path="$DEST/$fname"

	if [ -f "$dest_path" ]; then
		skipped=$((skipped + 1))
		continue
	fi

	echo "sync-mirror: fetching $fname"
	# Download to a .part file first so a failed/interrupted transfer never
	# leaves a truncated file under its real name (which the flat try_files
	# nginx config would then serve as if it were complete).
	if wget -q -O "$dest_path.part" "$url"; then
		mv "$dest_path.part" "$dest_path"
		fetched=$((fetched + 1))
	else
		echo "sync-mirror: FAILED to fetch $fname" >&2
		rm -f "$dest_path.part"
		failed=$((failed + 1))
	fi
done < "$SOURCES"

echo "sync-mirror: $total sources checked, $fetched fetched, $skipped already present, $failed failed"

if [ "$failed" -gt 0 ]; then
	exit 1
fi
