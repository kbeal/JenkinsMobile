#!/bin/sh

#  makeBallsAtlas.sh
#  JenkinsMobile
#
#  Created by Kyle Beal on 1/29/16.
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
rm -rf $WORK_PATH/*
mkdir -p $IMAGES_OUTPUT_PATH/balls${SIZE}.atlas

# clean up and get a fresh clone
git clone $JENKINS_GIT_URL $WORK_PATH/jenkins

for color in grey blue yellow red green
do
    # convert the image's svg to png
    $INKSCAPE -z -e $IMAGES_OUTPUT_PATH/balls${SIZE}.atlas/${color}.png -w $SIZE -h $SIZE $WORK_PATH/jenkins/war/images/${color}.svg
done
