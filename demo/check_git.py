#!/usr/bin/env python

'''
This demo script will show how to get Git information from python
'''

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


print("Current git commit is: {0}".format(parse_git(attribute = "hash")))
print("Current git commit is: {0}".format(parse_git(attribute = "hash_short")))
print("Current git branch is: {0}".format(parse_git(attribute = "branch")))
print("Validating current git branch...")
validate_git_branch()
print("Success!")
