#!/usr/bin/env python
# tested with python 2.7

'''
This script will parse the RunParameters.xml file from a NextSeq run
'''


import sys
import os
import argparse
from settings import *
from python_functions import *

# ~~~~ CUSTOM FUNCTIONS ~~~~~~ #
def make_params_dict(params_file):
    '''
    return a dictionary of values from the RunParameters_xml_file xml file for a run
    '''
    import xml.etree.ElementTree as ET
    from collections import OrderedDict
    tree = ET.parse(params_file)
    root = tree.getroot()
    find_keys = ['RunID', 'ExperimentName', 'LibraryID', 'InstrumentID', 'RunStartDate', 'ComputerName', 'BaseSpaceRunId', 'RunNumber', 'OutputFolder', 'RunFolder']
    params_dict = OrderedDict()
    for key in find_keys:
        params_dict[key] = root.find(key).text
        # print('{0}: {1}'.format(key, root.find(key).text))
    return(params_dict)

def make_run_index():
    '''
    Make the index for all runs in the NextSeq sequencer dir
    '''
    import settings
    sequencer_dir = settings.nextseq_dir # from settings
    index_dir = mkdirs(os.path.join(sequencer_dir, "run_index"), return_path = True)
    index_file = os.path.join(index_dir, "index.csv")
    backup_file(index_file)
    # params_file_list = find_run_params(sequencer_dir)
    params_file_list = find_files(search_dir = sequencer_dir, search_filename = 'RunParameters.xml')
    params_dicts = []
    for file in params_file_list:
        params_dicts.append(make_params_dict(file))
    print('Writing new index to file:\n{0}\n\n'.format(index_file))
    write_dicts_to_csv(dict_list = params_dicts, output_file = index_file)

def print_run_params(project_ID):
    '''
    Search for a single run's params file and print it to the console
    '''
    import settings
    project_dir = os.path.join(settings.nextseq_dir, project_ID)
    RunParameters_xml_file = find_files(search_dir = project_dir, search_filename = 'RunParameters.xml')[0]
    params_dict = make_params_dict(RunParameters_xml_file)
    print_dict(params_dict)

def run(args):
    '''
    Evaluate the args passed and run the script accordingly
    '''
    # import settings
    project_IDs = []
    for ID in args.project_IDs:
        project_IDs.append(ID)
    for ID in project_IDs:
        print_run_params(ID)
    if args.index_mode == True:
        make_run_index()


# ~~~~ GET SCRIPT ARGS ~~~~~~ #
parser = argparse.ArgumentParser(description='NextSeq RunParameters.xml Parser')
# positional args
parser.add_argument("project_IDs", nargs='*', help="NextSeq runs to be evaluated individually.")

# optional flags
parser.add_argument("--index", default = False, action='store_true', dest = 'index_mode', help="Create a new index of all runs in the NextSeq directory.")

args = parser.parse_args()

if __name__ == "__main__":
    run(args)
