#!/bin/bash

[ -d "libs" ] && rm -r libs
mkdir libs
curl -L https://www.wowace.com/projects/ace3/files/latest -o Ace3.zip

unzip Ace3.zip
cp -r Ace3/AceAddon-3.0 libs
cp -r Ace3/AceConfig-3.0 libs
cp -r Ace3/AceDB-3.0 libs
cp -r Ace3/AceDBOptions-3.0 libs
cp -r Ace3/AceGUI-3.0 libs
cp -r Ace3/CallbackHandler-1.0 libs
cp -r Ace3/LibStub libs

rm -r Ace3
rm Ace3.zip
