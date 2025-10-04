#!/bin/bash
#### VARIABLE SECTION START ###
# Some values
COLLECTION="Musikverein"
INSTRUMENTGROUP="Schlagwerk" # This one is  used to create the pdf containing all the parts scanned

# Init Scanner Use the scanner ID found with "scanimage --list-devices"
SCANNER="pixma:04A91913_597E72"
# Output Folder
OUTPUTFOLDER="/home/chaapp/onedrive/Notenordner/Musikverein"

#### VARIABLE SECTION END ###

# Init page variable for counting pages which is needed for the pages deaclation in CSV
PAGE=0


cd $OUTPUTFOLDER

# Frage nach Titel
echo "Song-Title: "
read titleinput
TITLE=$titleinput

# Create Title folder
mkdir "$TITLE"
cd "$TITLE"
TITLETRIM=`echo $TITLE | tr -d '[:blank:]'`
echo $TITLETRIM

# Ask for Artist
echo "Artist: "
read artistinput
ARTIST=$artistinput

# Ask for Genre
echo "Genre: "
read genreinput
GENRE=$genreinput

# Ask for Composer
echo "Composer: "
read composerinput
COMPOSER=$composerinput

# Create headline of CSV for MobileSheets import
echo "title;pages;setlists;collections;artist;albums;genres;composer;source types;custom groups" > import.csv

# Init some counter variables
SCANENDE=0
STIMMENENDE=0

# start out loop for the whole scan

while [ $SCANENDE -lt 1 ]
do
    # Ask for the part
    echo "Which Part are you scanning? (1=Drums, 2=Percussion, 3=Mallets, 4=Timpani, 5=put in text )  "
    read STIMMECHOICE
    if [ $STIMMECHOICE == 1 ]; then
	STIMME="Drums"
    elif [ $STIMMECHOICE == 2 ]; then
	STIMME="Percussion"
    elif [ $STIMMECHOICE == 3 ]; then
	STIMME="Mallets"
    elif [ $STIMMECHOICE == 4 ]; then
	STIMME="Timpani"    
    elif [ $STIMMECHOICE == 5 ]; then
	echo "Custom part name: "
	read STIMMETEXT
	STIMME=$STIMMETEXT    
    else
	echo "Wrong input"
    fi
    # init Counter for part
    STIMMEPAGE=0
    
    # Inner loop for part-scanning until SCANENDE=1
    while [ $STIMMENENDE -lt 1 ]
    do
	# Set number of startpage for the part
	STIMMEPAGESTART=$PAGE
	# increment page counter whole scan
	PAGE=$(($PAGE + 1))
	# increment page counter part
	STIMMEPAGE=$(($STIMMEPAGE + 1))

	# Some output for information
	echo "Scanning $TITLE - $STIMME - $STIMMEPAGE"
	echo "Overallpage: $PAGE"

	# Scanning the images with Lineart (black/white)
	read -p "Press enter to continue scanning"
	scanimage -d $SCANNER --mode Lineart --resolution 300 --format=jpeg > "$TITLETRIM-$PAGE-$STIMME".jpg

	# Ask if part is ready
	echo "Did you scan all pages of the part? (y/n): "
	read STIMMENENDEINPUT

	# If not ready go on scanning and reenter loop
	if [ $STIMMENENDEINPUT == "n" ]; then
	    STIMMENENDE=0
	# if ready do some stuff
	else
	    echo "Part is ready, going on"
	    echo "Converting $TITLETRIM-$STIMME*.jpg"
	    # Create a pdf for the part
	    convert $TITLETRIM-*-$STIMME.jpg "$TITLE-$STIMME.pdf"
	    # Finnisch the counters for the pages
	    STIMMEPAGESTART=$(($PAGE - $STIMMEPAGE + 1))
	    STIMMEPAGEENDE=$(($PAGE))
	    echo $STIMMEPAGESTART
	    echo $STIMMEPAGEENDE
	    # Write the line  for the part into the MobileSheets csv import ready CSV file which contains Metadata and pages
	    echo "$TITLE;$STIMMEPAGESTART-$STIMMEPAGEENDE;;$COLLECTION;$ARTIST;;$GENRE;$COMPOSER;$STIMME;$INSTRUMENTGROUP" >> import.csv
	    STIMMENENDE=1
	    break
	fi
    done
    STIMMENENDE=0

    # Ask if the whoe scan should be finnished
    echo "Is the whole scan done? (y/n)"
    read SCANENDEINPUT

    if [ $SCANENDEINPUT == "n" ]; then
	SCANENDE=0
	echo "Sanning next part... "
    else
	SCANENDE=1
	echo "Scan will be finnished "
    fi
    
done

# Create a pdf of all the parts
convert $TITLETRIM*.jpg "$TITLE-Schlagwerk.pdf"

# Write the line  for the part into the MobileSheets csv import ready CSV file which contains Metadata and pages
echo "$TITLE;1-$PAGE;;$COLLECTION;$ARTIST;;$GENRE;$COMPOSER;$INSTRUMENTGROUP;$INSTRUMENTGROUP" >> import.csv

# Cleanup
rm *.jpg
