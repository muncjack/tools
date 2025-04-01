

This of all this script is not afileated with zoom.us

The script manage the install of zoom by integrating into the debian / ubuntu 
package manager.

This script does not build the zoom package it on downloads it from zooms web 
site and create a local repo so apt can see it and noce if the is a new version
 and update as part of the default OS update. 

### why 

I was pained by the manual process to update zoom, I tried contacting and raised a
 ticket to suggest having a nice setup with a apt repo. But they started talking about 
universal installers (zoom does shine good bad ideas and maybe a security problem 
in the future ..), if zoom.us feel like you need some help setting up a repo
 feel free to ask :-)  

### How Does it work? 

On the first run it will run the setup function which will

1. get the current gpg key from zoom.us web site and added it to the gpg key repo

2. create the apt config in /etc/sources.d

3. download and add it self to the system in /opt/tools/script

4. run the update package


### how does the update tool work ?

1. run wget in mirror mode to download update the local copy if needed 

2. create the Packages file needed for a depo location 

3. the script will self update (may change in the future)


### Howto install

Open a terminal and run the folowing:

```bash
wget -q "https://raw.githubusercontent.com/muncjack/tools/refs/heads/main/zoom/zoom_update_script.sh" -O - | bash 
```
