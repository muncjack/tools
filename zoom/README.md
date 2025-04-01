


This script is a script to manage  the install of zoom by integrating into the
debian / ubuntu package manager.

This scrip does not build the zoom package it on down loads it from zooms web 
site and create a local repo so apt can see it and noce if the is a new version
 and update as part of the default OS update. 


### How Does it work? 

on the first run it will run the setup function which will

1. get the current gpg key from zoom.us web site and added it to the gpg key repo

2. create the apt config in /etc/sources.d

3. download and add it self to the system in /opt/tools/script

4. run the update package


### how does the update tool work ?

1. run wget in mirror mode to download update the local copy if needed 

2. create the Packages file needed for a depo location 

3. self update is included 


### Howto install

Open a terminal and run the folowing:

```bash
wget https://github.com/muncjack/tools/blob/main/zoom/zoom_update_script.sh | bash 
```
