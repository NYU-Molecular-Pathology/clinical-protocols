#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Sets up and updates a SQLite database for tracking samples in runs
"""
import os
import find
import sqlite3
from util import sqlite_tools as sqt

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

def find_samplesheet(run_dir):
    """
    Finds the samplesheet in the run dir
    """
    matches = find.find(search_dir = run_dir, inclusion_patterns = ['SampleSheet.csv'], search_type = "file")
    return(matches)

def update_db_runs(conn, run_dirs):
    """
    Check the database to make sure all run dirs are present with samplesheets
    """
    for path in run_dirs:
        run = os.path.basename(path)
        if not sqt.row_exists(conn = conn, table_name = "runs", col_name = "run", value = run):
            print('Run dir doesnt exist in database: {0}; searching for samplesheet...'.format((run, path)))
            samplesheet_matches = find_samplesheet(run_dir = path)
            if len(samplesheet_matches) > 1:
                print("ERROR: multiple files were found; {0}".format(samplesheet_matches))
                raise
            elif len(samplesheet_matches) < 1:
                print("WARNING: no files were found in dir; {0}".format(path))
                continue
            else:
                samplesheet = samplesheet_matches.pop()
                print("Adding samplesheet: {0}".format(samplesheet))
                row = {'run': run, 'path': path, 'samplesheet': samplesheet}
                sqt.sqlite_insert(conn = conn, table_name = "runs", row = row)
        else:
            print('Run dir already exists in database: {0}; skipping...'.format((run, path)))


# ~~~~~ RUN ~~~~~ #
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

# create csv dumps of database
table_names = sqt.get_table_names(conn = conn)
for name in table_names:
        output_file = "{0}.csv".format(name)
        sqt.dump_csv(conn = conn, table_name = name, output_file = output_file)

# ~~~~~ CLEAN UP ~~~~~ #
conn.commit()
conn.close()
