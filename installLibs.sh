#!/bin/bash

mkdir libs
wget -O Ace.zip https://media.forgecdn.net/files/3078/383/Ace3-Release-r1241.zip
unzip Ace.zip
cp -r Ace/AceAddon-3.0 libs
cp -r Ace/AceConfig-3.0 libs
cp -r Ace/AceDB-3.0 libs
cp -r Ace/AceDBOptions-3.0 libs
cp -r Ace/AceGUI-3.0 libs
cp -r Ace/CallbackHandler-1.0 libs
cp -r Ace/LibStub libs
