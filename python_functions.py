#!/usr/bin/env python
# tested with python 2.7

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

def print_dict(mydict):
    '''
    pretty printing for dict entries
    '''
    for key, value in mydict.items():
        print('{}: {}\n\n'.format(key, value))

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

def write_dicts_to_csv(dict_list, output_file):
    '''
    write a list of dicts to a CSV file
    '''
    import csv
    with open(output_file, 'w') as outfile:
        fp = csv.DictWriter(outfile, dict_list[0].keys())
        fp.writeheader()
        fp.writerows(dict_list)

def backup_file(input_file, return_path=False):
    '''
    backup a file by moving it to a folder called 'old' and appending a timestamp
    '''
    import os
    if os.path.isfile(input_file):
        filename, extension = os.path.splitext(input_file)
        new_filename = '{0}.{1}{2}'.format(filename, timestamp(), extension)
        new_filename = os.path.join(os.path.dirname(new_filename), "old", os.path.basename(new_filename))
        mkdirs(os.path.dirname(new_filename))
        print('Backing up old file:\n{0}\n\nTo location:\n{1}\n'.format(input_file, new_filename))
        os.rename(input_file, new_filename)
    if return_path:
        return input_file

def find_files(search_dir, search_filename):
    '''
    return the paths to all files matching the supplied filename in the search dir
    '''
    import os
    print('Now searching for file "{0}" in directory {1}'.format(search_filename, search_dir))
    file_list = []
    for root, dirs, files in os.walk(search_dir):
        for file in files:
            if file == search_filename:
                found_file = os.path.join(root, file)
                file_list.append(found_file)
    print('Found {0} matches'.format(len(file_list)))
    return(file_list)

def print_json(object):
    import json
    print(json.dumps(object, sort_keys=True, indent=4))

def write_json(object, output_file):
    import json
    with open(output_file,"w") as f:
        json.dump(object, f, sort_keys=True, indent=4)

def load_json(input_file):
    import json
    with open(input_file,"r") as f:
        my_item = json.load(f)
    return my_item

def walklevel(some_dir, level=1):
    '''
    Recursively search a directory for all items up to a given depth
    use it like this:
    file_list = []
    for item in pf.walklevel(some_dir):
        if ( item.endswith('my_file.txt') and os.path.isfile(item) ):
            file_list.append(item)
    '''
    import os
    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        # yield root, dirs, files
        for dir in dirs:
            yield os.path.join(root, dir)
        for file in files:
            yield os.path.join(root, file)
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]
