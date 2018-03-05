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
    sqt.create_table(conn = conn, table_name = "samples", col_name = "hash", col_type = "TEXT", is_primary_key = True) # multiple samples per run

def find_samplesheet(run_dir):
    """
    Finds the samplesheet in the run dir
    """
    matches = find.find(search_dir = run_dir, inclusion_patterns = ['SampleSheet.csv'], search_type = "file")
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
    # validate search results
    if len(samplesheet_matches) > 1:
        print("ERROR: multiple files were found; {0}".format(samplesheet_matches))
        raise
    elif len(samplesheet_matches) < 1:
        print("WARNING: no SampleSheet files were found in dir; {0}".format(path))
        return(None)
    else:
        # update the runs table
        samplesheet_file = samplesheet_matches.pop()
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

force_update = False
# ~~~~~ RUN ~~~~~ #
if __name__ == '__main__':
    args = sys.argv[1:]
    try:
        force_val = args.pop(0)
    except:
        force_val = None
    if force_val == "force":
        force_update = True

    db_file = "nextseq.sqlite"
    # connect to db
    conn = sqlite3.connect(db_file)
    setup_db(conn = conn)

    # directory with sequencer output
    seq_dir = '/ifs/data/molecpathlab/quicksilver/'

    # get the list of available runs
    run_dirs = get_runs(seq_dir = seq_dir)

    # check the database for each run to see if the samplesheet needs to be added
    update_db_runs(conn = conn, run_dirs = run_dirs)

    # dump the entire database
    db_dump_file = os.path.join(os.path.dirname(db_file), '{0}.dump.txt'.format(os.path.basename(db_file)))
    sqt.dump_sqlite(conn = conn, output_file = db_dump_file)

    # create csv dumps of database
    table_names = sqt.get_table_names(conn = conn)
    for name in table_names:
            output_file = "{0}.csv".format(name)
            sqt.dump_csv(conn = conn, table_name = name, output_file = output_file)

    # ~~~~~ CLEAN UP ~~~~~ #
    conn.commit()
    conn.close()
