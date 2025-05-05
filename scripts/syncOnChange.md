SyncOnChange
------------


This script is very synple fisrt param is the location to monitored for change 
and the second is the command to be executed when the file changes.

In the second param use the {} to indicate the file/dir to be replaced.

Before starting the script you will be python3 inotify on debian/ubuntu install

'''bash
sudo apt install python3-inotify
'''

If you don't give any params two default params will be used
 * '/tmp'
 * 'echo change to {}'
examples calling rsync on file change:

'''bash
syncOnChange.py ./ 'rsync -av {} dofus:RaspberryPi/'
'''
'''bash 
syncOnChange.py ./ 'rsync -av {,dofus:myfolder/}{}'
'''

In the process of doing some research I did find, I did find some existing scripts:

 * https://pypi.org/project/py-mon/
 * 