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

def json_dumps(object):
    import json
    return(json.dumps(object, sort_keys=True, indent=4))


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


def parse_git(attribute):
    '''
    Check the current git repo for one of the following items
    attribute = "hash"
    attribute = "hash_short"
    attribute = "branch"
    '''
    import sys
    import subprocess
    command = None
    if attribute == "hash":
        command = ['git', 'rev-parse', 'HEAD']
    elif attribute == "hash_short":
        command = ['git', 'rev-parse', '--short', 'HEAD']
    elif attribute == "branch":
        command = ['git', 'rev-parse', '--abbrev-ref', 'HEAD']
    if command != None:
        try:
            return(subprocess.check_output(command).strip()) # python 2.7+
        except subprocess.CalledProcessError:
            print('\nERROR: Git branch is not configured. Exiting script...\n')
            sys.exit()

def print_iter(iterable):
    '''
    basic printing of every item in an iterable object
    '''
    for item in iterable: print(item)

def validate_git_branch(allowed = ('master', 'production')):
    import sys
    import subprocess
    try:
        current_branch = parse_git(attribute = "branch")
        if current_branch not in allowed:
            print("ERROR: current branch is not allowed! Branch is: {0}.".format(current_branch))
            print("Allowed branches are:")
            print_iter(allowed)
            print("Exiting...")
            sys.exit()
    except subprocess.CalledProcessError:
        print('\nERROR: Git branch is not configured. Exiting script...\n')
        sys.exit()

def subprocess_cmd(command, return_stdout = False):
    # run a terminal command with stdout piping enabled
    import subprocess as sp
    process = sp.Popen(command,stdout=sp.PIPE, shell=True, universal_newlines=True)
     # universal_newlines=True required for Python 2 3 compatibility with stdout parsing
     # https://stackoverflow.com/a/27775464/5359531
    proc_stdout = process.communicate()[0].strip()
    if return_stdout == True:
        return(proc_stdout)
    elif return_stdout == False:
        print(proc_stdout)


def get_qsub_job_ID_name(proc_stdout):
    '''
    return a tuple of the form (<id number>, <job name>)
    usage:
    proc_stdout = submit_qsub_job(return_stdout = True) # 'Your job 1245023 ("python") has been submitted'
    job_id, job_name = get_qsub_job_ID_name(proc_stdout)
    '''
    import re
    proc_stdout_list = proc_stdout.split()
    job_id = proc_stdout_list[2]
    job_name = proc_stdout_list[3]
    job_name = re.sub(r'^\("', '', str(job_name))
    job_name = re.sub(r'"\)$', '', str(job_name))
    return((job_id, job_name))


def submit_qsub_job(command = 'echo foo', params = '-j y', name = "python", stdout_log_dir = '${PWD}', stderr_log_dir = '${PWD}', return_stdout = False, verbose = False):
    '''
    submit a job to the SGE cluster with qsub
    '''
    import subprocess
    qsub_command = '''
qsub {0} -N {1} -o :{2}/ -e :{3}/ <<E0F
{4}
E0F
'''.format(params, name, stdout_log_dir, stderr_log_dir, command)
    if verbose == True:
        print('Command is:\n{0}'.format(qsub_command))
    proc_stdout = subprocess_cmd(command = qsub_command, return_stdout = True)
    if return_stdout == True:
        return(proc_stdout)
    elif return_stdout == False:
        print(proc_stdout)

def check_qsub_job_status(job_id, desired_status = "r"):
    '''
    Use 'qstat' to check on the run status of a qsub job
    returns True or False if the job status matches the desired_status
    job running:
    desired_status = "r"
    job waiting:
    desired_status = "qw"
    NOTE: This does not work in Python 3+ because of string decoding requirements on the qstat_stdout object
    '''
    import re
    from sh import qstat
    job_id_pattern = r"^.*{0}.*\s{1}\s.*$".format(job_id, desired_status)
    qstat_stdout = qstat()
    # qstat_stdout = subprocess_cmd('qstat', return_stdout = True)
    job_match = re.findall(str(job_id_pattern), str(qstat_stdout), re.MULTILINE)
    job_status = bool(job_match)
    if job_status == True:
        status = True
        return(job_status)
    elif job_status == False:
        return(job_status)

def wait_qsub_job_start(job_id, return_True = False):
    '''
    Monitor the output of 'qstat' to determine if a job is running or not
    equivalent of
    '''
    from time import sleep
    import sys
    print('waiting for job to start')
    while check_qsub_job_status(job_id = job_id, desired_status = "r") != True:
        sys.stdout.write('.')
        sys.stdout.flush()
        sleep(1) # Time in seconds.
    print('')
    if check_qsub_job_status(job_id = job_id, desired_status = "r") == True:
        print('job {0} has started'.format(job_id))
        if return_True == True:
            return(True)


def demo_qsub():
    '''
    Demo the qsub code functions
    '''
    command = '''
    set -x
    cat /etc/hosts
    sleep 300
    '''
    proc_stdout = submit_qsub_job(command = command, verbose = True, return_stdout = True)
    job_id, job_name = get_qsub_job_ID_name(proc_stdout)
    print('Job ID: {0}'.format(job_id))
    print('Job Name: {0}'.format(job_name))
    wait_qsub_job_start(job_id)
