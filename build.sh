#!/bin/bash

mkdir Auto-Camera
cp *.lua Auto-Camera
cp -r modules Auto-Camera
cp -r libs Auto-Camera
cp *.xml Auto-Camera
cp Auto-Camera.toc Auto-Camera
zip -r Auto-Camera.zip Auto-Camera
cp Auto-Camera-Classic.toc Auto-Camera/Auto-Camera.toc
zip -r Auto-Camera-classic.zip Auto-Camera
cp Auto-Camera-BCC.toc Auto-Camera/Auto-Camera.toc
zip -r Auto-Camera-bcc.zip Auto-Camera
rm -r Auto-Camera
