#!/usr/bin/env python
# python 2.7 required!

'''
This script will search the data output directory for the NextSeq,
find all the "RunParameters.xml" files,
get information from each file,
and build a CSV format index with information from all the data found for each run
'''

import sys
import os
import csv

# ~~~~ CUSTOM FUNCTIONS ~~~~~~ #
def my_debugger(vars):
    '''
    starts interactive Python terminal at location in script
    very handy for debugging
    call this function with
    my_debugger(globals().copy())
    anywhere in the body of the script, or
    my_debugger(locals().copy())
    within a script function
    '''
    import readline # optional, will allow Up/Down/History in the console
    import code
    # vars = globals().copy() # in python "global" variables are actually module-level
    vars.update(locals())
    shell = code.InteractiveConsole(vars)
    shell.interact()

def timestamp():
    '''
    Return a timestamp string
    '''
    import datetime
    return('{:%Y-%m-%d-%H-%M-%S}'.format(datetime.datetime.now()))

def mkdirs(path, return_path=False):
    '''
    Make a directory, and all parent dir's in the path
    '''
    import sys
    import os
    import errno
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise
    if return_path:
        return path

def find_run_params(search_dir):
    '''
    return the paths to all "RunParameters.xml" files in a directory
    '''
    import os
    params_file_list = []
    for root, dirs, files in os.walk(search_dir):
        for file in files:
            if file == "RunParameters.xml":
                params_file = os.path.join(root, file)
                params_file_list.append(params_file)
    return(params_file_list)

def make_params_dict(params_file):
    '''
    return a dictionary of values from the params xml file for a run
    '''
    import xml.etree.ElementTree as ET
    from collections import OrderedDict
    tree = ET.parse(params_file)
    root = tree.getroot()
    find_keys = ['RunID', 'ExperimentName', 'LibraryID', 'OutputFolder', 'InstrumentID', 'RunStartDate']
    params_dict = OrderedDict()
    for key in find_keys:
        params_dict[key] = root.find(key).text
        # print('{0}: {1}'.format(key, root.find(key).text))
    return(params_dict)

def write_dicts_to_csv(dict_list, output_file):
    '''
    write a list of dicts to a CSV file
    '''
    import csv
    with open(output_file, 'w') as outfile:
        fp = csv.DictWriter(outfile, dict_list[0].keys())
        fp.writeheader()
        fp.writerows(dict_list)

def backup_file(input_file):
    '''
    backup a file by moving it to a folder called 'old' and appending a timestamp
    '''
    import os
    if os.path.isfile(input_file):
        filename, extension = os.path.splitext(input_file)
        new_filename = '{0}.{1}{2}'.format(filename, timestamp(), extension)
        new_filename = os.path.join(os.path.dirname(new_filename), "old", os.path.basename(new_filename))
        mkdirs(os.path.dirname(new_filename))
        print('Backing up file:\n{0}\n\nTo location:\n{1}\n\n'.format(input_file, new_filename))
        os.rename(input_file, new_filename)

if __name__ == "__main__":
    sequencer_dir = "/ifs/data/molecpathlab/quicksilver"
    index_dir = mkdirs(os.path.join(sequencer_dir, "run_index"), return_path = True)
    index_file = os.path.join(index_dir, "index.csv")
    backup_file(index_file)
    params_file_list = find_run_params(sequencer_dir)
    params_dicts = []
    for file in params_file_list:
        params_dicts.append(make_params_dict(file))
    print('Writing new index to file:\n{0}\n\n'.format(index_file))
    write_dicts_to_csv(dict_list = params_dicts, output_file = index_file)
