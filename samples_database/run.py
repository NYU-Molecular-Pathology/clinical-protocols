#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Sets up and updates a SQLite database for tracking samples in runs
"""
import os
import sys
import find
import sqlite3
from util import samplesheet
from util import sqlite_tools as sqt
from util import tools

# ~~~~~ FUNCTIONS ~~~~~ #
def get_runs(seq_dir):
    """
    Gets the available runs from the parent sequencer data output directory
    """
    run_dirs = find.find(search_dir = seq_dir, exclusion_patterns = ['to_be_demultiplexed', 'automatic_demultiplexing_logs', 'run_index', '*_test*', '*_run_before_sequencing_done'], search_type = 'dir', level_limit = 0)
    return(run_dirs)

def setup_db(conn):
    """
    Initializes the database with columns and tables
    """
    sqt.create_table(conn = conn, table_name = "runs", col_name = "run", col_type = "TEXT", is_primary_key = True)
    sqt.add_column(conn = conn, table_name = "runs", col_name = "path", col_type = "TEXT")
    sqt.add_column(conn = conn, table_name = "runs", col_name = "samplesheet", col_type = "TEXT")
    sqt.create_table(conn = conn, table_name = "settings", col_name = "run", col_type = "TEXT", is_primary_key = True) # each run has one settings entry
    sqt.create_table(conn = conn, table_name = "params", col_name = "run", col_type = "TEXT", is_primary_key = True) # each run has one params entry
    sqt.create_table(conn = conn, table_name = "samples", col_name = "hash", col_type = "TEXT", is_primary_key = True) # multiple samples per run

    sqt.create_table(conn = conn, table_name = "NGS580_samples", col_name = "hash", col_type = "TEXT", is_primary_key = True)
    sqt.create_table(conn = conn, table_name = "NGS580_runs", col_name = "run", col_type = "TEXT", is_primary_key = True)

def find_samplesheet(run_dir):
    """
    Finds the samplesheet in the run dir
    """
    matches = find.find(search_dir = run_dir, inclusion_patterns = ['SampleSheet.csv'], search_type = "file")
    return(matches)

def find_RunParametersxml(run_dir):
    """
    """
    matches = find.find(search_dir = run_dir, inclusion_patterns = ['RunParameters.xml'],
                        search_type = "file", num_limit = 1, level_limit = 1, match_mode = "all")
    return(matches)

def load_samplesheet_data(samplesheet_file):
    """

    Examples
    --------
    Example usage::

        x = "SampleSheet.csv"
        run_settings, run_samples = load_samplesheet_data(x)

    """
    data = samplesheet.IEMFile(path = samplesheet_file)
    run_settings = {}
    run_settings.update(data.data['Reads'])
    run_settings.update(data.data['Header'])
    run_settings.update(data.data['Settings'])
    run_samples = data.data['Data']['Samples']
    return((run_settings, run_samples))

def update_run_samplesheet(conn, path, run, samplesheet_matches):
    """
    Adds the SampleSheet.csv contents to the database

    Parameters
    ----------
    conn: sqlite3.Connection object
        connection object to the database
    path: str
        path to the run directory
    run: str
        Name of the run
    samplesheet_matches: list
        a list of files matching sample sheet search criteria
    """
    if len(samplesheet_matches) > 1:
        print("ERROR: multiple files were found; {0}".format(samplesheet_matches))
        raise
    elif len(samplesheet_matches) < 1:
        print("WARNING: no SampleSheet files were found in dir; {0}".format(path))
        return(None)
    else:
        # update the runs table
        samplesheet_file = samplesheet_matches.pop(0)
        print("Adding samplesheet: {0}".format(samplesheet_file))
        row = {'run': run, 'path': path, 'samplesheet': samplesheet_file}
        sqt.sqlite_insert(conn = conn, table_name = "runs", row = row)
        # get the sample information from the sheet
        run_settings, run_samples = load_samplesheet_data(samplesheet_file)
        # update sample information & add to db
        run_settings['run'] = run
        run_settings = sqt.sanitize_dict_keys(d = run_settings)
        for key in run_settings.keys():
            sqt.add_column(conn = conn, table_name = "settings", col_name = key, col_type = "TEXT")

        sqt.sqlite_insert(conn = conn, table_name = "settings", row = run_settings)

        for run_sample in run_samples:
            run_sample['run'] = run
            run_sample['hash'] = sqt.md5_str(''.join(run_sample.values()))
            run_sample = sqt.sanitize_dict_keys(d = run_sample)
            for key in run_sample.keys():
                sqt.add_column(conn = conn, table_name = "samples", col_name = key, col_type = "TEXT")
            sqt.sqlite_insert(conn = conn, table_name = "samples", row = run_sample)

def update_run_RunParametersxml(conn, path, run, run_parameters_xml_matches):
    """
    Adds the RunParameters.xml contents to the database

    Parameters
    ----------
    conn: sqlite3.Connection object
        connection object to the database
    path: str
        path to the run directory
    run: str
        Name of the run
    run_parameters_xml_matches: list
        a list of files matching run_parameters_xml search criteria
    """
    # validate search results
    if len(run_parameters_xml_matches) < 1:
        print("WARNING: no RunParameters.xml files were found in dir; {0}".format(path))
        return(None)
    else:
        # update the runs table
        run_parameters_file = run_parameters_xml_matches.pop(0)
        print("Adding RunParameters: {0}".format(run_parameters_file))
        row = {'run': run, 'path': path, 'RunParameters': run_parameters_file}
        # get the sample information from the sheet
        run_params = samplesheet.RunParametersXML(path = run_parameters_file).data
        # update sample information & add to db
        run_params['run'] = run
        run_params = sqt.sanitize_dict_keys(d = run_params)
        sqt.sqlite_insert(conn = conn, table_name = "params", row = run_params, add_missing_cols = True)



def update_db_run(conn, path, run):
    """
    Update a single run in the db

    Parameters
    ----------
    conn: sqlite3.Connection object
        connection object to the database
    path: str
        path to the run directory
    run: str
        Name of the run

    """
    # find the samplesheet
    samplesheet_matches = find_samplesheet(run_dir = path)
    update_run_samplesheet(conn = conn, path = path, run = run, samplesheet_matches = samplesheet_matches)

    # find the RunParameters.xml
    run_parameters_xml_matches = find_RunParametersxml(run_dir = path)
    # TODO: fix this it currentl breaks on SQL insert
    update_run_RunParametersxml(conn = conn, path = path, run = run, run_parameters_xml_matches = run_parameters_xml_matches)

def update_db_runs(conn, run_dirs):
    """
    Check the database to make sure all run dirs are present with samplesheets
    """
    for path in run_dirs:
        # run ID = dir basename
        run = os.path.basename(path)
        # check if the run is already in the db
        if not sqt.row_exists(conn = conn, table_name = "runs", col_name = "run", value = run):
            # find the samplesheet
            print('Run dir doesnt exist in database: {0}; searching for samplesheet...'.format((run, path)))
            update_db_run(conn = conn, path = path, run = run)
        # TODO: fix this doesn't work due to SQLite restrictions
        # elif force_update:
        #     print('Run dir already exists in database, forcing update for: {0}; searching for samplesheet...'.format((run, path)))
        #     update_db_run(conn = conn, path = path, run = run)
        else:
            print('Run dir already exists in database: {0}; skipping...'.format((run, path)))


def update_db_NGS580(conn, path, run, results):
    """
    Updates a single analysis result's entries in the database
    """
    # create 'run' entry
    run_row = {'run': run, 'path': path, 'results': results}
    # add to the db
    print("adding run to database: {0}".format(run_row))
    sqt.sqlite_insert(conn = conn, table_name = "NGS580_runs", row = run_row, add_missing_cols = True)

    samples_fastq_files = find.find(search_dir = path, inclusion_patterns = ["samples.fastq-raw.csv"],
                                    search_type = 'file', level_limit = 1, match_mode = "all", num_limit = 1)
    samples_pairs_files = find.find(search_dir = path, inclusion_patterns = ["samples.pairs.csv"],
                                    search_type = 'file', level_limit = 1, match_mode = "all", num_limit = 1)

    # parse the files
    samples_fastq_file = samplesheet.SamplesFastqRawCSV(path = samples_fastq_files[0])
    samples_pairs_file = samplesheet.SamplesPairsCSV(path = samples_pairs_files[0])

    # merge the data into a single entry per sample
    samples = []
    for sample in samples_fastq_file.samples:
        for pair in samples_pairs_file.pairs:
            sample_dict = {}
            if sample == pair['Tumor']:
                sample_dict['Sample'] = sample
                sample_dict.update(pair)
                sample_dict['path'] = path
                sample_dict['run'] = run
                sample_dict['results'] = results
                sample_dict['hash'] = sqt.md5_str(''.join([str(i) for i in sample_dict.values()]))
                samples.append(sample_dict)
    for sample in samples:
        print("adding sample to database: {0}".format(sample))
        sqt.sqlite_insert(conn = conn, table_name = "NGS580_samples", row = sample, add_missing_cols = True)





def update_db_NGS580s(conn, analysis_dir, filter_file):
    """
    Check the database to make sure all NGS580 analysis metadata is present
    """
    # get allowed 'results dir' paths from text file
    results_dirs = []
    with open(filter_file) as f:
        for line in f.readlines():
            results_dirs.append(line.strip())

    # find the analysis results directories and files
    matches = [ m for m in find.find(search_dir = analysis_dir, inclusion_patterns = ["results_*"],
                                    search_type = 'dir', level_limit = 1, match_mode = "all") if m in results_dirs ]

    for path in matches:
        run = os.path.basename( os.path.dirname(path) )
        results = os.path.basename( path )

        # check if the run is already in the db
        if not sqt.row_exists(conn = conn, table_name = "NGS580_runs", col_name = "run", value = run):
            # find the samplesheet
            print('NGS580 analysis doesnt exist in database: {0}; searching for files...'.format((run, results, path)))
            update_db_NGS580(conn = conn, path = path, run = run, results = results)
        else:
            print('NGS580 analysis already exists in database: {0}; skipping...'.format((run, results, path)))





force_update = False
# ~~~~~ RUN ~~~~~ #
if __name__ == '__main__':
    # ~~~~~ SETTINGS ~~~~~ #
    args = sys.argv[1:]
    try:
        force_val = args.pop(0)
    except:
        force_val = None
    if force_val == "force":
        force_update = True

    db_name = "nextseq"
    db_dir = "/ifs/data/molecpathlab/quicksilver/run_index"
    db_file = "{0}.sqlite".format(db_name)
    db_path = os.path.join(db_dir, db_file)
    print("db_path: {0}".format(db_path))
    # connect to db
    conn = sqlite3.connect(db_path)
    setup_db(conn = conn)

    # directory with sequencer output
    seq_dir = '/ifs/data/molecpathlab/quicksilver'
    print("seq_dir: {0}".format(seq_dir))

    # directory with NGS580 analysis outputs
    NGS580_dir = "/ifs/data/molecpathlab/NGS580_WES"
    # file with list of analysis results subdirs to include
    NGS580_results_dir_file = "results_dirs.txt"





    # ~~~~~ UPDATE ~~~~~ #
    # get the list of available runs
    run_dirs = get_runs(seq_dir = seq_dir)

    # check the database for each run to see if the samplesheet needs to be added
    update_db_runs(conn = conn, run_dirs = run_dirs)

    update_db_NGS580s(conn = conn, analysis_dir = NGS580_dir, filter_file = NGS580_results_dir_file)




    # ~~~~~ CLEAN UP ~~~~~ #
    # dump the entire database
    db_dump_file = os.path.join(os.path.dirname(db_path), '{0}.sqlite.dump.txt'.format(db_name))
    sqt.dump_sqlite(conn = conn, output_file = db_dump_file)

    # create csv dumps of database
    table_names = sqt.get_table_names(conn = conn)
    for name in table_names:
            output_file = os.path.join(os.path.dirname(db_path), "{0}.{1}.csv".format(db_name, name))
            sqt.dump_csv(conn = conn, table_name = name, output_file = output_file)
    conn.commit()
    conn.close()
