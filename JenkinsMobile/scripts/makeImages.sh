#!/bin/sh

#  makeImages.sh
#  JenkinsMobile
#
#  Clones Jenkins CI project from github and converts the svgs for various images
#  to png with sizes specified.
#
#
#  this script requires these tools to be installed:
#  * inkscape (http://inkscape.org/)
#
#
#  Created by Kyle Beal on 3/23/16.
#  Copyright © 2016 Kyle Beal. All rights reserved.


set -e

USAGE="Usage: ./makeImages.sh"
JENKINS_GIT_URL="https://github.com/jenkinsci/jenkins.git"
WORK_PATH=~/tmp/jenkinsmobile
IMAGES_OUTPUT_PATH=$WORK_PATH/images
INKSCAPE=/Applications/Inkscape.app/Contents/Resources/bin/inkscape

# clean up and get a fresh clone
echo "Setting up "$WORK_PATH
rm -rf $WORK_PATH/jenkins
mkdir -p $IMAGES_OUTPUT_PATH


git clone $JENKINS_GIT_URL $WORK_PATH/jenkins

# these sizes represent those used in current Images.xcassets for all size classes
for size in 360 240 216 144 120 72
do
# convert the image's svg to png
$INKSCAPE -z -e $IMAGES_OUTPUT_PATH/orange-square-${size}.png -w $size -h $size $WORK_PATH/jenkins/war/images/orange-square.svg
done



