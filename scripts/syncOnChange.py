#!/usr/bin/env python3

import os
from sys import argv
import inotify.adapters

location = '/tmp'
action = 'echo change to {}'

def _main(location, action):
    i = inotify.adapters.Inotify()

    i.add_watch(location)

    #with open('/tmp/test_file', 'w'):
    #    pass

    for event in i.event_gen(yield_nones=False):
        (_, type_names, path, filename) = event
        if 'IN_CLOSE_WRITE' in type_names:
            print("PATH=[{}] FILENAME=[{}] EVENT_TYPES={}".format(
              path, filename, type_names))
            os.system(action.format(filename))

if __name__ == '__main__':
    print(f'starting to monitor: {location} and will be running "{action}"')
    if len(argv) > 1:
        location = argv[1]
        if len(argv) > 2:
            action = argv[2]
    _main(location, action)

# hello there