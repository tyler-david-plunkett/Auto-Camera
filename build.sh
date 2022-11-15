#!/bin/bash

# scan for versions
addonVersion=$1
retailInterfaceVersion=`grep "## Interface" Auto-Camera.toc | grep -oEi "[0-9]*"`
classicInterfaceVersion=`grep "## Interface" Auto-Camera-Classic.toc | grep -oEi "[0-9]*"`
bccInterfaceVersion=`grep "## Interface" Auto-Camera-BCC.toc | grep -oEi "[0-9]*"`
wrathInterfaceVersion=`grep "## Interface" Auto-Camera-Wrath.toc | grep -oEi "[0-9]*"`

mkdir Auto-Camera
cp *.lua Auto-Camera
cp -r modules Auto-Camera
cp -r libs Auto-Camera
cp *.xml Auto-Camera

# create retail artifact
cp Auto-Camera.toc Auto-Camera
zip -r Auto-Camera.zip Auto-Camera

# create classic artifact
cp Auto-Camera-Classic.toc Auto-Camera/Auto-Camera.toc
zip -r Auto-Camera-classic.zip Auto-Camera

# create bcc artifact
cp Auto-Camera-BCC.toc Auto-Camera/Auto-Camera.toc
zip -r Auto-Camera-bcc.zip Auto-Camera

# create bcc artifact
cp Auto-Camera-Wrath.toc Auto-Camera/Auto-Camera.toc
zip -r Auto-Camera-wrath.zip Auto-Camera

# create release.json
releaseJSON='{"releases":[{"name":"Auto-Camera","version":"%s","filename":"Auto-Camera-%s.zip","nolib": false,"metadata":[{"flavor":"mainline","interface":%s}]},{"name":"Auto-Camera","version":"%s","filename":"Auto-Camera-%s-classic.zip","nolib": false,"metadata":[{"flavor":"classic","interface":%s}]},{"name":"Auto-Camera","version":"%s","filename":"Auto-Camera-%s-bcc.zip","nolib": false,"metadata":[{"flavor":"bcc","interface":%s}]},{"name":"Auto-Camera","version":"%s","filename":"Auto-Camera-%s-wrath.zip","nolib": false,"metadata":[{"flavor":"wrath","interface":%s}]}]}'
printf "$releaseJSON" "$addonVersion" "$addonVersion" "$retailInterfaceVersion" "$addonVersion" "$addonVersion" "$classicInterfaceVersion" "$addonVersion" "$addonVersion" "$bccInterfaceVersion" "$addonVersion" "$addonVersion" "$wrathInterfaceVersion" > release.json

# clean up
rm -r Auto-Camera
