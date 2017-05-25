#!/usr/bin/env python
# python 2.7 required!

'''
Run this script with crontab
This script will ...
- check for samplesheets deposited in the samplesheet dir, if found parse them and start demultiplexing as appropriate
'''


import sys
import os
import csv
# from settings import *
import settings # bash & python settings
import python_functions as pf

# ~~~~ CUSTOM FUNCTIONS ~~~~~~ #

def load_settings():
    '''
    Load the default sequencer settings file
    '''
    sequencing_settings = pf.load_json(settings.sequencer_settings_file)
    return(sequencing_settings)

def validate_samplesheet(item):
    '''
    Validate whether an item is a Sample Sheet
    -type f -name "*-SampleSheet.csv"
    '''
    import os
    status = False
    if (os.path.isfile(item) and item.endswith('-SampleSheet.csv')):
        status = True
    return(status)

def get_samplesheet_list(dir):
    '''
    Gets a list of sample sheet files from a directory
    '''
    import os
    samplesheet_list = []
    for item in os.listdir(dir):
        item_path = os.path.join(dir, item)
        if validate_samplesheet(item_path):
            samplesheet_list.append(item_path)
    return(samplesheet_list)

def check_for_samplesheets(sequencing_settings):
    '''
    Check the auto_demultiplex_dir dirs defined in the settings
    '''
    # for sequencing_type, values in sequencing_settings['sequencing_types'].items():
        # print(sequencing_type, values)
    test_dir = "/ifs/data/molecpathlab/test_data/NGS580"
    processed_dir = "/ifs/data/molecpathlab/test_data/processed"
    in_progress_dir = "/ifs/data/molecpathlab/test_data/in-progress"
    samplesheet_list = get_samplesheet_list(test_dir)
    print(samplesheet_list)
    print(pf.timestamp())



def run():
    '''
    Main function to run the monitoring program
    '''
    sequencing_settings = load_settings()
    check_for_samplesheets(sequencing_settings)
    # pf.print_json(sequencing_settings)


if __name__ == "__main__":
    run()
