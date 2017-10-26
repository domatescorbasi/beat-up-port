# beat-up-port

![alt text](https://i.imgur.com/sWsVRVr.png "Beat-up-port Logo")

# DESCRIPTION
**Beat-up-port** is a command-line program to download musics of Beatport top 100 chart via Youtube or SoundCloud. It is compatible with Unix-like systems It is released to the public domain, which means you can modify it, redistribute it or use it however you like.

Downloads the music categorically into appropriate folders depending on the genre.

# Usage
### Set your variables in the script
DLDIR="/path/to/dir" # Where  downloaded music should reside.      

DATADIR="/path/to/dir" # Where logs and top100 info should reside.

### Example :
_DLDIR="$HOME/Youtube_Music_Feed"_

_DATADIR="$HOME/.local/share/beat-up-port"_

### And run
$: ./beat-up-port.sh

# Warning
Dont put / at the end of the folder name on path variables.

Do not run this script as **root**.

# Dependency
youtube-dl

lynx
