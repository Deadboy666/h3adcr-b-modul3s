#!/usr/bin/env bash
set -eu

SteamInstallDir=$HOME/.steam/steam
FlatpakSteamInstallDir=$HOME/.var/app/com.valvesoftware.Steam/.steam/steam
FlatpakSLSsteamInstallDir=$HOME/.var/app/com.valvesoftware.Steam/.local/share/SLSsteam
FlatpakSLSsteamConfigDir=$HOME/.var/app/com.valvesoftware.Steam/.config/SLSsteam
SLSsteamInstallDir=$HOME/.local/share/SLSsteam
SLSsteamConfigDir=$HOME/.config/SLSsteam
Headcrab_Downgrader_Path=$HOME/.headcrab
TRASHITE_DIR=/usr/local/bin

  read_os_release(){
        local f
        OS_ID=""
        OS_ID_LIKE=""
        for f in /etc/os-release /usr/lib/os-release; do
            [ -r "$f" ] || continue
            . "$f"
            break
        done
        OS_ID=${ID:-}
        OS_ID_LIKE=${ID_LIKE:-}
    }

  bazzitecheck(){
        read_os_release
        [ "$OS_ID" = "bazzite" ]
        }

  confirm(){
        local prompt="$1"
        printf "%s [y/N] " "$prompt"
        read -r reply
        case "$reply" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            *) return 1 ;;
        esac
        }

  checkfortrashitestupidity(){
    cd $TRASHITE_DIR/
    if [ -f "steam.save" ]; then
      echo "Purging The Deprecated Methods"
      sudo rm {steam.save,steam}
   elif [ -f "bazzite-steam" ]; then
      echo "Purging The Deprecated Methods"
      sudo rm {bazzite-steam,steam}
  elif [ -f "steam" ]; then
      echo "Purging The Deprecated Methods"
      sudo rm steam
    else
      echo "Bazzite Install Unmodified"
    fi
      echo "" &> /dev/null
      }

  fixtrashite(){
    if bazzitecheck ; then
      checkfortrashitestupidity
      ujust update
    else
        echo "" &> /dev/null
    fi
      echo "" &> /dev/null
      }



  wheresteam(){
        if [ -d "$FlatpakSteamInstallDir" ]; then
                flatpak run com.valvesoftware.Steam "$@"
        else
                steam "$@"
            fi
                echo "" &> /dev/null
            }

  resetlaunch(){
        rm -rf "$Headcrab_Downgrader_Path"
        if [ -d "$FlatpakSteamInstallDir" ]; then
               cd $FlatpakSteamInstallDir/
               echo "" $FlatpakSteamInstallDir/.steam-disable-steamrt64-client
        else
                cd $SteamInstallDir/
                echo "" $SteamInstallDir/.steam-disable-steamrt64-client
            fi
                revertsteam
            }

    revertsteam(){
      if [ -f steam.cfg ]; then
        rm steam.cfg
      else
        echo "steam.cfg does not exist"
      fi
        rm steam.sh

        if confirm "Remove Millennium (millennishit)?"; then
          purgemillennishit
        else
          echo "Skipping Millennium Removal"
        fi
        }

    purgemillennishit(){
    echo "Searching For Millennium"
      if [ -f "ubuntu12_32/libXtst.so.6" ]; then
        echo "Unlinking Millennium"
        rm "ubuntu12_32/libXtst.so.6"
      else
        echo "Millennium Not Found"
      fi
        echo "" &> /dev/null
        }


  PurgeHeadcrab(){
    echo "Bashing The Headcrab With A Cr0wbar.."
    resetlaunch
    echo "Headcrab Despawned Out Of The Enviroment Reloading Save.."
    wheresteam -exitsteam
    fixtrashite
    }

echo "Headcrab Uninstaller"
PurgeHeadcrab
