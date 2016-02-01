#!/bin/sh

#  makeBalls.sh
#  JenkinsMobile
#
#  Clones Jenkins CI project from github and converts the svgs for the status balls
#  to png with size specified and necessary opacities.
#
#
#  this script requires these tools to be installed:
#  * ImageMagick (http://www.imagemagick.org/)
#  * inkscape (http://inkscape.org/)
#
#
#  Created by Kyle Beal on 1/27/16.
#  Copyright © 2016 Kyle Beal. All rights reserved.


set -e

SIZE=$1

USAGE="Usage: ./makeBalls.sh size"
JENKINS_GIT_URL="https://github.com/jenkinsci/jenkins.git"
WORK_PATH=~/tmp/jenkinsmobile
IMAGES_OUTPUT_PATH=$WORK_PATH/images
INKSCAPE=/Applications/Inkscape.app/Contents/Resources/bin/inkscape

# check parameters
if [ $# -ne 1 ]
then
    echo $USAGE
    exit 1
fi

echo "Setting up "$WORK_PATH
rm -rf $WORK_PATH/jenkins
mkdir -p $IMAGES_OUTPUT_PATH

# clean up and get a fresh clone
git clone $JENKINS_GIT_URL $WORK_PATH/jenkins

for color in grey blue yellow red green
do
    # convert the image's svg to png
    $INKSCAPE -z -e $IMAGES_OUTPUT_PATH/${color}-${SIZE}-100.png -w $SIZE -h $SIZE $WORK_PATH/jenkins/war/images/${color}.svg
    # Create the image with various opacities for blinking animation. 
    convert $IMAGES_OUTPUT_PATH/${color}-${SIZE}-100.png -alpha on -channel A -evaluate multiply .2 +channel $IMAGES_OUTPUT_PATH/${color}-${SIZE}-20.png
    convert $IMAGES_OUTPUT_PATH/${color}-${SIZE}-100.png -alpha on -channel A -evaluate multiply .4 +channel $IMAGES_OUTPUT_PATH/${color}-${SIZE}-40.png
    convert $IMAGES_OUTPUT_PATH/${color}-${SIZE}-100.png -alpha on -channel A -evaluate multiply .6 +channel $IMAGES_OUTPUT_PATH/${color}-${SIZE}-60.png
    convert $IMAGES_OUTPUT_PATH/${color}-${SIZE}-100.png -alpha on -channel A -evaluate multiply .8 +channel $IMAGES_OUTPUT_PATH/${color}-${SIZE}-80.png
done
