#!/usr/bin/env python
# tested with python 2.7

'''
This script will parse the RunParameters.xml file from a NextSeq run
'''


import sys
import os
import argparse
import settings
import python_functions as pf

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
    sequencer_dir = settings.nextseq_dir # from settings
    # index_dir = pf.mkdirs(os.path.join(sequencer_dir, "run_index"), return_path = True)
    # index_file = os.path.join(index_dir, "index.csv")
    index_file = settings.NextSeq_index_file
    pf.backup_file(index_file)
    # use walklevel because there are a lot more dirs to search in this case
    params_file_list = []
    for item in pf.walklevel(sequencer_dir):
        if ( item.endswith('RunParameters.xml') and os.path.isfile(item) ):
            params_file_list.append(item)
    params_dicts = []
    for file in params_file_list:
        params_dicts.append(make_params_dict(file))
    print('Writing new index to file:\n{0}\n\n'.format(index_file))
    pf.write_dicts_to_csv(dict_list = params_dicts, output_file = index_file)

def find_run_params(project_ID):
    '''
    Search for a single run's params file and print it to the console
    '''
    project_dir = os.path.join(settings.nextseq_dir, project_ID)
    RunParameters_xml_file = pf.find_files(search_dir = project_dir, search_filename = 'RunParameters.xml')[0]
    return(RunParameters_xml_file)

def print_run_params(RunParameters_xml_file, name_mode = False):
    '''
    print a single run's params file to the console
    '''
    params_dict = make_params_dict(RunParameters_xml_file)
    if name_mode == True:
        key = "ExperimentName"
        if key in params_dict.keys():
            value = params_dict[key]
            print('{}'.format(value))
    else:
        for key, value in params_dict.items():
            print('{}: {}\n\n'.format(key, value))

def main(project_IDs, file_mode, index_mode, name_mode):
    '''
    Main script control function
    '''
    project_items = []
    for item in project_IDs:
        project_items.append(item)
    if file_mode == True:
        for file in project_items:
            print_run_params(file, name_mode = name_mode)
    else:
        for ID in project_items:
            RunParameters_xml_file = find_run_params(ID)
            print_run_params(RunParameters_xml_file, name_mode = name_mode)
    if index_mode == True:
        make_run_index()


def run():
    '''
    Evaluate the args & run the script
    '''
    # ~~~~ GET SCRIPT ARGS ~~~~~~ #
    parser = argparse.ArgumentParser(description='NextSeq RunParameters.xml Parser')
    # positional args
    parser.add_argument("project_IDs", nargs='*', help="NextSeq output run directory names to be evaluated individually.")

    # optional flags
    parser.add_argument("--index", default = False, action='store_true', dest = 'index_mode', help="Create a new index of all runs in the NextSeq directory.")
    parser.add_argument("--name", default = False, action='store_true', dest = 'name_mode', help="Print only the ExperimentName value from the params file(s).")
    parser.add_argument("-f", "--file", default = False, action='store_true', dest = 'file_mode', help="Treat input items as paths to XML files.")

    args = parser.parse_args()
    main(**vars(args))

if __name__ == "__main__":
    run()
