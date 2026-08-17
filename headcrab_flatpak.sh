#!/usr/bin/env bash


    STEAM_CLIENT="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/client.sh"
    INJECT_SLS="LD_AUDIT=$HOME/.var/app/com.valvesoftware.Steam/.local/share/SLSsteam/library-inject.so:$HOME/.var/app/com.valvesoftware.Steam/.local/share/SLSsteam/SLSsteam.so"
    NOTIF="$HOME/.local/share/icons/hicolor/48x48/apps/headcrab.png"
    FlatpakSteamInstallDir=$HOME/.var/app/com.valvesoftware.Steam/.steam/steam
    SteamInstallDir=$HOME/.steam/steam


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

    archcheck(){
        read_os_release
        case " $OS_ID $OS_ID_LIKE " in
            *" arch "*|*" cachyos "*) return 0 ;;
        esac
        return 1
        }

    debiancheck(){
        read_os_release
        case " $OS_ID $OS_ID_LIKE " in
            *" debian "*|*" ubuntu "*) return 0 ;;
        esac
        return 1
        }

    steamoscheck(){
        read_os_release
        [ "$OS_ID" = "steamos" ]
        }

	voidcheck(){
        read_os_release
        [ "$OS_ID" = "void" ]
        }

	cachyoscheck(){
        read_os_release
        [ "$OS_ID" = "cachyos" ]
        }

	bazzitecheck(){
        read_os_release
        [ "$OS_ID" = "bazzite" ]
        }

    flatpakcheck(){
        [ -d "$FlatpakSteamInstallDir" ]
        }

        SteamOSClientCheck(){
        if [ -f "steam_client_steamdeck_stable_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_stable_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable"
        elif [ -f steam_client_steamdeck_publicbeta_ubuntu12.manifest ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
			echo "SteamClientChannel: Beta"
			echo "Reverting To Stable Client With DGSC"
		else
			echo "Unknown Version Number"
        fi
            echo "SteamClientType: SteamOS"
        }

	BazziteClientCheck(){
        if [ -f "steam_client_steamdeck_stable_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_stable_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable (Bazzite-Deck)"
        elif [ -f steam_client_steamdeck_publicbeta_ubuntu12.manifest ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta (Bazzite-Deck)"
		elif [ -f "steam_client_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable (Bazzite-Desktop)"
		else
            versionnumber=$(grep '"version"' steam_client_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta (Bazzite-Desktop)"
        fi
            echo "SteamClientType: Bazzite"
        }

	CachyClientCheck(){
        if [ -f "steam_client_steamdeck_stable_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_stable_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable (CachyOS-Handheld)"
        elif [ -f steam_client_steamdeck_publicbeta_ubuntu12.manifest ]; then
            versionnumber=$(grep '"version"' steam_client_steamdeck_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta (CachyOS-Handheld)"
		elif [ -f "steam_client_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable (CachyOS-Desktop)"
		else
            versionnumber=$(grep '"version"' steam_client_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta (CachyOS-Desktop)"
        fi
            echo "SteamClientType: CachyOS"
        }

    FlatpakClientCheck(){
        if [ -f "steam_client_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable"
        else
            versionnumber=$(grep '"version"' steam_client_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta"
        fi
            echo "SteamClientType: Flatpak"
        }

    NativeClientCheck(){
        if [ -f "steam_client_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable"
        else
            versionnumber=$(grep '"version"' steam_client_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta"
        fi
            echo "SteamClientType: Native"
        }

	VoidClientCheck(){
        if [ -f "steam_client_ubuntu12.manifest" ]; then
            versionnumber=$(grep '"version"' steam_client_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Stable"
        else
            versionnumber=$(grep '"version"' steam_client_publicbeta_ubuntu12.manifest | awk -F'"' '{print $4}')
            echo "SteamClientChannel: Beta"
        fi
            echo "SteamClientType: Void"
        }

        CheckClientInfo(){
        echo "SteamClientInfo:"
        wheresteampackage
        if steamoscheck; then
            SteamOSClientCheck
		elif bazzitecheck; then
            BazziteClientCheck
		elif cachyoscheck; then
			CachyClientCheck
		elif voidcheck; then
			VoidClientCheck
        elif flatpakcheck; then
            FlatpakClientCheck
        else
            NativeClientCheck
        fi
            echo "HeadcrabClientVersion: $versionnumber"
            echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            cat ~/.var/app/com.valvesoftware.Steam/.SLSsteam.log
            echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            notify-send -e -i $NOTIF -a "h3adcr-b " "The Headcrab Approaches.. " "Client: $versionnumber "  & sleep 1s
            }

            wheresteampackage(){
        if [ -d "$FlatpakSteamInstallDir" ]; then
               cd $FlatpakSteamInstallDir/package
        else
                cd $SteamInstallDir/package
            fi
                echo "" &> /dev/null
            }

       GameLauncher(){
        CheckClientInfo
        echo "Loaded SLSsteam" & export $INJECT_SLS &> /dev/null
        source $STEAM_CLIENT "$@" &> /dev/null
        }



    steam(){
        GameLauncher "$@"
        }

   steam "$@"
