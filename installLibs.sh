#!/bin/bash

mkdir libs
wget -O Ace3.zip https://media.forgecdn.net/files/3078/383/Ace3-Release-r1241.zip
unzip Ace3.zip
cp -r Ace3/AceAddon-3.0 libs
cp -r Ace3/AceConfig-3.0 libs
cp -r Ace3/AceDB-3.0 libs
cp -r Ace3/AceDBOptions-3.0 libs
cp -r Ace3/AceGUI-3.0 libs
cp -r Ace3/CallbackHandler-1.0 libs
cp -r Ace3/LibStub libs
