#!/bin/bash

mkdir Auto-Camera
cp *.lua Auto-Camera
cp -r modules Auto-Camera
cp -r libs Auto-Camera
cp *.xml Auto-Camera
cp Auto-Camera.toc Auto-Camera
zip -r Auto-Camera.zip Auto-Camera
rm Auto-Camera/Auto-Camera.toc
cp Auto-Camera-Classic.toc Auto-Camera
zip -r Auto-Camera-classic.zip Auto-Camera
rm Auto-Camera/Auto-Camera-classic.toc
cp Auto-Camera-BCC.toc Auto-Camera
zip -r Auto-Camera-bcc.zip Auto-Camera
rm -r Auto-Camera
