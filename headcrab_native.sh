#!/usr/bin/env bash


    STEAM_CLIENT="$HOME/.steam/steam/client.sh"
    INJECT_SLS="LD_AUDIT=$HOME/.local/share/SLSsteam/library-inject.so:$HOME/.local/share/SLSsteam/SLSsteam.so"

       GameLauncher(){
        export $INJECT_SLS &> /dev/null
        source $STEAM_CLIENT "$@"
        }



    steam(){
        GameLauncher "$@"
        }

   steam "$@"
