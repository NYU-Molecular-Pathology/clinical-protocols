#!/usr/bin/env python
# tested with python 2.7

'''
USAGE: nextseq_sample_index.py
This script will parse the SampleSheet.csv files found in all NextSeq runs to build a sample index
'''


import sys
import os
import csv
import linecache
import argparse
import settings
import python_functions as pf
import parse_run_params_xml

# ~~~~ CUSTOM FUNCTIONS ~~~~~~ #
def get_runs():
    '''
    Check the NextSeq dir for a list of subdirs that represent potential runs to be searched
    return a dict of format
    dict['runID'] = "path/to/run"
    '''
    runs = {}
    nextseq_dir = settings.nextseq_dir
    for fname in os.listdir(nextseq_dir):
        path = os.path.join(nextseq_dir, fname)
        if os.path.isdir(path):
            runs[fname] = {}
            runs[fname]['run_dir'] = path
    return(runs)

def get_samplesheet(run_dir, relative_path = "Data/Intensities/BaseCalls/SampleSheet.csv"):
    '''
    Get a list of all the samplesheets to be evaluated
    '''
    item_path = os.path.join(run_dir, relative_path)
    if os.path.exists(item_path):
        return(item_path)
    else:
        return(None)


def find_samplesheet_startrow(samplesheet):
    '''
    samplesheet = filepath to samplesheet
    Find the index of the row in the samplesheet file that corresponds with the header for the [Data] section;
    looks like this:
    [Data],,,,,,
Sample_ID,Sample_Name,I7_Index_ID,index,Sample_Project,Description,GenomeFolder
    '''
    # default_colnames = ['Sample_ID', 'Sample_Name', 'I7_Index_ID', 'index', 'Sample_Project', 'Description', 'GenomeFolder']
    default_colnames = ['Sample_ID', 'Sample_Name']
    with open (samplesheet, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        for i, row in enumerate(reader):
            if set(default_colnames).issubset(row):
                return(i)

def get_samples(samplesheet):
    '''
    Get a list of samples from the samplesheet
    '''
    if samplesheet == None: return(None)
    samples_list = []
    samplesheet_startrow = find_samplesheet_startrow(samplesheet)
    with open (samplesheet, 'r') as csvfile:
        # skip to the start of the samples
        for i in range(samplesheet_startrow):
            csvfile.next()
        reader = csv.DictReader(csvfile, delimiter=',')
        for i, row in enumerate(reader):
            row['samplesheet'] = samplesheet
            samples_list.append(row)
    return(samples_list)

def get_run_ID(samplesheet, relative_path = "Data/Intensities/BaseCalls/SampleSheet.csv"):
    '''
    Get the run ID from the dirname of the run; find it from the filepath to the SampleSheet.csv
    '''
    nextseq_dir = settings.nextseq_dir
    import re
    url = 'abcdc.com'
    url = re.sub('\.com$', '', url)

def get_run_params_XML(run_dir):
    '''
    Find the RunParameters.xml file for the run
    '''
    for item in pf.walklevel(run_dir):
        if ( item.endswith('RunParameters.xml') and os.path.isfile(item) ):
            return(item)

def get_run_params(run_params_XML):
    '''
    Get the run params from the XML
    '''
    if run_params_XML != None:
        params_dict = parse_run_params_xml.make_params_dict(params_file = run_params_XML)
        return(params_dict)
    else:
        return(None)


def main():
    '''
    Main script control function
    '''
    runs = get_runs()
    for run, items in runs.items():
        runs[run]['run_type'] = 'NGS580'
        run_dir = runs[run]['run_dir']

        # get run params XML
        run_params_XML = get_run_params_XML(run_dir)
        runs[run]['run_params_XML'] = run_params_XML
        runs[run]['run_params'] = get_run_params(run_params_XML)

        # get samplesheet
        samplesheet = get_samplesheet(run_dir)
        runs[run]['samplesheet'] = samplesheet
        runs[run]['samples'] = get_samples(samplesheet)

    pf.print_json(runs)
    # now what to do with the information??




def run():
    '''
    Evaluate the args & run the script
    '''
    main()

if __name__ == "__main__":
    run()
