# scan-score.sh Bash script for music scores from sheet music for MobilSheets

Thi Bash-Script can be used to scan sheet music with a (USB-)scanner on linus.
It is especially made for the use with  the App [MobileSheets](https://www.zubersoft.com/mobilesheets/). 
You can scan various parts in one run of the script. I use it mostly for scanning percussion sheet music for a wind band, which typically includes multiple parts, like 'drums', 'percussion', 'mallets', 'timpani' and so.


## requirements
- Linux computer (bash)
- CLI tool `scanimage`
- a scanner connected to the computer

## input

**Following variables need to be specified hardcoded iside the script:**
- COLLECTION (Collection name for Mobile sheets, in my case the name of the band "Musikverein")
- INSTRUMENTGROUP (In My case this is "Schlagwerk", the german word for the group of percussion instruments)
- SCANNER (The ID of the hardware scannern found with `scanimage --list-devices`
- OUTPUTFOLDER (The target directory)

It also asks for some metadata:
- Title
- Genre
- Artist
- Composer

## output

In the script you can declare an output folder, whih will be the working directory.
The script will always create a new directory with the Song-Title as directory name.

As a result you will get following structure inside the OUTPUTFOLDER:

``` shell
OUTPUTFOLDER/TITLE-PART1.pdf 
OUTPUTFOLDER/TITLE-PART2.pdf
...
OUTPUTFOLDER/TITLE-INSTRUMENTGROUP.pdf
OUTPUTFOLDER/import.csv
```

So you habe dedicated PDF files for all parts and a summarized PDF file for the Instrumentgroup.
This summarized PDF, together with the CSV file is designed for the CSV-import function of the app [MobileSheets](https://www.zubersoft.com/mobilesheets/)

By using this function you will be able to import all the parts with the same title and appropriate metadata for all the parts.

Just use the CSV import function, select the CSV and the summarized pdf and MobileSheets will automatically discover the metadata and splits the PDF file internally like needed.

# installation

Download the sh script and make it executable:

`chmod 744 scan-score.sh`

Change the variables in the variable section `#### VARIABLE SECTION START ###` to fit your needs.
Find your scanner ID: `scanimage --list-devices`


# usage
In a bash shell:
`./scan-score.sh`

The cli includes a menu that guides you through the scan process.




