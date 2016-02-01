#!/bin/sh

#  makeHealthIcons.sh
#  JenkinsMobile
#
#  Clones Jenkins CI project from github and converts the svgs for the health icons
#  to png with size specified.
#
#
#  this script requires these tools to be installed:
#  * inkscape (http://inkscape.org/)
#
#
#  Created by Kyle Beal on 3/23/16.
#  Copyright © 2016 Kyle Beal. All rights reserved.


set -e

SIZE=$1

USAGE="Usage: ./makeHealthIcons.sh size"
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
#rm -rf $WORK_PATH/jenkins
#mkdir -p $IMAGES_OUTPUT_PATH

# clean up and get a fresh clone
#git clone $JENKINS_GIT_URL $WORK_PATH/jenkins

for health in 00to19 20to39 40to59 60to79 80plus
do
# convert the image's svg to png
$INKSCAPE -z -e $IMAGES_OUTPUT_PATH/health-${health}-${SIZE}.png -w $SIZE -h $SIZE $WORK_PATH/jenkins/war/images/health-${health}.svg
done
