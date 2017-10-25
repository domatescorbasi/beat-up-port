#! /bin/bash

# ***************************************************************************************
# *                  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                        *
# *                             Version 3, December 2017                                *
# *                                                                                     *
# *                           Copyright (C) 2017 Riza DOGAN                             *
# *                                                                                     *
# *           Everyone is permitted to copy and distribute verbatim or modified         *
# *          copies of this license document, and changing it is allowed as long        *
# *                                as the name is changed.                              *
# *                                                                                     *
# *                    DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE                      *
# *             TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION         *
# *                                                                                     *
# *                    0. You just DO WHAT THE FUCK YOU WANT TO.                        *
# ***************************************************************************************

# ***************************************************************************************
# *                         Beat Up Port is a scraper for Beatport.                     *
# *  Downloads the music categorically into appropriate folders depending on the genre. *
# *                         Usage : ./beat-up-port.sh                                   *
# *       Warning  : Dont put / at the end of the folder name on path variables.        *
# *                 Warning 2: Do not run this script as root.                          *
# ***************************************************************************************

# Set your path variables here
DLDIR="$HOME/Youtube_Music_Feed" # Where  downloaded music should reside.
DATADIR="$HOME/.local/share/beat-up-port" # Where logs and top100 info should reside.

# Do not fuck with these variables
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
FINE=${GREEN}+${NORMAL}
SHIT=${RED}-${NORMAL}
WHAT=${YELLOW}\?${NORMAL}
INFO=${YELLOW}\*${NORMAL}

declare -A GENRES=(["11"]="Tech House" ["6"]="Techno" ["12"]="Deep House" ["5"]="House" ["15"]="Progressive House" ["17"]="Electro House" ["37"]="Indie Dance - Nu Disco" ["3"]="Electronica - Downtempo" ["14"]="Minimal - Deep Tech" ["79"]="Big Room" ["7"]="Trance" ["81"]="Funky - Groove - Jackin' House" ["65"]="Future House" ["18"]="Dubstep" ["39"]="Dance" ["1"]="Drum & Bass" ["9"]="Breaks" ["2"]="Hardcore - Hard Techno" ["13"]="Psy-Trance" ["38"]="Hip-Hop - R&B" ["40"]="Funk - Soul - Disco" ["49"]="Glitch Hop" ["87"]="Trap - Future Bass" ["80"]="Leftfield House & Techno" ["8"]="Hard Dance" ["16"]="DJ Tools" ["41"]="Reggae - Dancehall - Dub" ["85"]="Leftfield Bass" ["86"]="Garage - Bassline - Grime"  ["100"]="Genreless Top 100 Ultimate List!!")

# Search google from terminal
google()
{
	Q="$*"; GOOG_URL='https://www.google.com/search?tbs=li:1&q=';
	AGENT="Mozilla/4.0";
	stream=$(curl -A "$AGENT" -skLm 10 "${GOOG_URL}${Q//\ /+}" |
		grep -oP '\/url\?q=.+?&amp' | sed 's|/url?q=||; s|&amp||');
	echo -e "${stream//\%/\x}";
}

# Check exit status of the last program and if necessary create log.
checkExitCode ()
{
	local i=$?
	if [ $i -ne 0 ]; then
		echo Could not download: "$line" >> "$DATADIR/logs/$GENNAME-logs.txt"
		echo "[$SHIT] Could not download: $line"
	else
		echo "[$FINE] Music has been downloaded succesfully"
	fi
}

# 25 songs per page * 4 page = top 100 songs chart
downloadTopSongs()
{
	echo "[$INFO] $GENNAME selected. Be patient, this may take a while ~[10-30]s "
	for ((page=1 ; page<=4 ; page++));
	do
	{
		lynx -listonly -source "https://www.beatport.com/charts/all?page=$page&genres=$genreID" \
		>> "$DATADIR/$GENNAME-linkdata.html"
	}
	done
}

# Parse the linkdata to get song names
parseTopSongs()
{
	sed 's/\ /\n/g' "$DATADIR/$GENNAME-linkdata.html" | grep "href=\"/chart/" |
	sed 's/"//g' | sed 's/href=\/chart\///g' | sed 's/\// /g' | sed 's/\ /\n/g' |
	grep '[a-zA-Z]' | sed 's/-chart//g' | sed 's/-/ /g' > "$DATADIR/$GENNAME"-song-list.txt
	echo "[$FINE] Top 100 Song chart has been downloaded"
}

houseKeeping()
{
	rm "$DATADIR/$GENNAME-linkdata.html"
	echo "[$FINE] Housekeeping..."
}

ultimateTopSongs()
{
	lynx -listonly -source https://www.beatport.com/top-100 > "$DATADIR/$GENNAME-linkdata.html"
	sed 's/\ /\n/g' "$DATADIR/$GENNAME-linkdata.html" | grep "href=\"/track/" | sed 's/"//g' | sed 's/href=\/track\///g' | sed 's/\// /g' | sed 's/\ /\n/g'|sed 's/^[[:space:]]*//g' |  grep '[a-zA-Z]'> "$DATADIR/$GENNAME-tracknames.txt"
	grep data-ec-d1= "$DATADIR/$GENNAME-linkdata.html" | sed 's/\t\t\tdata-ec-d1=\"//g' | sed 's/\"//g' |sed 's/^[[:space:]]*//g' > "$DATADIR/$GENNAME-artistnames.txt"
	grep data-ec-d3= "$DATADIR/$GENNAME-linkdata.html" | sed 's/\t\tdata-ec-d3=\"//g' | sed 's/\"//g' | sed 's/>//g'|sed 's/^[[:space:]]*//g'> "$DATADIR/$GENNAME-genrenames.txt"
	echo "[$FINE] Top 100 Song chart has been downloaded"
	houseKeeping
	for ((NUM=1 ; NUM<=100 ; NUM++))
	do
	{
		trackName=$(sed "${NUM}q;d" "$DATADIR/$GENNAME-tracknames.txt")
		artistName=$(sed "${NUM}q;d" "$DATADIR/$GENNAME-artistnames.txt")
		genreName=$(sed "${NUM}q;d" "$DATADIR/$GENNAME-genrenames.txt")
		youtube-dl "ytsearch:$trackName $artistName" -f 140 -o \
		"$HOME/Youtube_Music_Feed/Beatport/Ultimate 100!/$genreName/%(title)s.%(ext)s"
		checkExitCode
	}
	done
	echo "[$FINE] Housekeeping..."
	rm "$DATADIR/$GENNAME-tracknames.txt"
	rm "$DATADIR/$GENNAME-artistnames.txt"
	rm "$DATADIR/$GENNAME-genrenames.txt"
	exit
}

# Create [if necessary] the folders for data and logs
mkdir -p "$DATADIR/logs"

# Display selection list
for ID in "${!GENRES[@]}"; do printf "%s\t%s\n" "$ID" "${GENRES[$ID]}"; done

echo ""
echo "[$WHAT] Type the ${GREEN}Genre ID${NORMAL} that you want to download top 100 of from beatport"
read -r genreID
GENNAME=${GENRES[$genreID]}
if [[ $genreID -eq 100 ]]; then
	ultimateTopSongs
fi



if [[ -f "$DATADIR/$GENNAME-song-list.txt" ]]; then
	echo "[$INFO] $DATADIR/$GENNAME-song-list.txt exists."
	read -r -p "[$WHAT] Do you want to re-download the top 100 list? [y/N] " response
	response=${response,,}    # tolower
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		downloadTopSongs
		parseTopSongs
		houseKeeping
	fi
else
	downloadTopSongs
	parseTopSongs
	houseKeeping
fi

echo "[$FINE] Rip sequence initiating..."
while IFS='' read -r line || [[ -n "$line" ]]; do
	# Search google with the name of the song, youtube first
	searchResults=$(google "$line youtube $GENNAME") # Array of links
	downloadData=$(echo "${searchResults[@]}" | grep "youtube" | head -1 |
		sed 's/https:\/\/www.youtube.com\/watchx3Fvx3D//g')
	if [[ -n "$downloadData" ]]; then
		echo "[$FINE] Youtube link found"
		youtube-dl --flat-playlist  -f 140 -o \
			"$DLDIR/Beatport/$GENNAME/%(uploader)s/%(title)s.%(ext)s" \
			"$downloadData"
		checkExitCode
	else
		# If youtube link is not found
		# Search google with the name of the song, try to find soundcloud link
		echo "[$SHIT] Youtube link is not found, trying soundcloud."
		searchResults=$(google "$line soundcloud $GENNAME") # Array of links
		downloadData=$(echo "${searchResults[@]}" | grep "soundcloud" |
			 head -1)
		if [[ -n "$downloadData" ]]; then
			echo "[$FINE] Soundcloud link found"
			youtube-dl --flat-playlist  -f 140 -o \
				"$DLDIR/Beatport/$GENNAME/%(uploader)s/%(title)s.%(ext)s" \
				"$downloadData"
			checkExitCode
		else
			echo "[$SHIT] Soundcloud link not found either. "
			echo "[$SHIT$SHIT$SHIT] Skipping: $line."
			echo No existing links: "$line" >> "$DATADIR/logs/$GENNAME"-logs.txt
		fi
	fi
done < "$DATADIR/$GENNAME-song-list.txt"

echo "[$INFO] There are $(grep -c "Could not download:" "$DATADIR/logs/$GENNAME"-logs.txt) songs that were not able to be ripped by this script."
echo "[$INFO] You may want to try downloading these songs manually"
grep "Could not download:" "$DATADIR/logs/$GENNAME"-logs.txt

echo "[$SHIT] There are $(grep -c "No existing links:" "$DATADIR/logs/$GENNAME"-logs.txt) [ unpublished / not public ] music."
grep "No existing links:" "$DATADIR/logs/$GENNAME"-logs.txt
