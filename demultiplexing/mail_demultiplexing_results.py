#!/usr/bin/env python

'''
Mail the results from demultiplexing
'''
# ~~~~ LOAD PACKAGES ~~~~~~ #
import os
import sys
import yaml
import logging
import logging.config

import mutt
import parse_run_params_xml
import python_functions as pf



# ~~~~ CUSTOM CLASSES ~~~~~~ #
class Container(object):
    '''
    basic container for information
    '''
    pass


# ~~~~ CUSTOM FUNCTIONS ~~~~~~ #
def get_locations(project_ID):
    '''
    Make a bundle of file and directory locations for the run
    '''
    import settings # common Python/bash locations settings file

    locations = Container()
    locations.project_ID = project_ID
    locations.auto_demultiplex_log_dir = settings.auto_demultiplex_log_dir
    locations.nextseq_dir = settings.nextseq_dir
    locations.demultiplexing_email_recipients_file = settings.demultiplexing_email_recipients_file
    locations.NextSeq_index_file = settings.NextSeq_index_file
    locations.project_dir = os.path.join(locations.nextseq_dir, project_ID)
    locations.RunParametersXML = os.path.join(locations.project_dir, "RunParameters.xml")
    locations.basecalls_dir = os.path.join(locations.project_dir, "Data", "Intensities", "BaseCalls")
    locations.unaligned_dir = os.path.join(locations.basecalls_dir, "Unaligned")
    locations.demultiplexing_stats_dir = os.path.join(locations.unaligned_dir, "demultiplexing-stats")
    locations.demultiplexing_stats_html = os.path.join(locations.demultiplexing_stats_dir, '{0}_demultiplexing_report.html'.format(project_ID)) # 170609_NB501073_0013_AHF7K3BGX2_demultiplexing_report.html

    return(locations)

def get_logpath_values():
    '''
    Retrieve values needed to set the log paths
    '''
    # per-project items from main
    logfile_dir = main.auto_demultiplex_log_dir
    project_ID = main.project_ID
    # logfile_dir = os.path.dirname(os.path.realpath(__file__))
    scriptname = os.path.basename(__file__)
    return((logfile_dir, project_ID, scriptname))

def logpath():
    '''
    Return the path to the main log file
    '''
    logfile_dir, project_ID, scriptname = get_logpath_values()
    log_file = os.path.join(logfile_dir, '{0}.{1}.{2}.debug.log'.format(scriptname, project_ID, timestamp))
    return(logging.FileHandler(log_file))

def email_logpath():
    '''
    Return the path to the main log file
    '''
    logfile_dir, project_ID, scriptname = get_logpath_values()
    log_file = os.path.join(logfile_dir, '{0}.{1}.{2}.info.log'.format(scriptname, main.project_ID, timestamp))
    return(logging.FileHandler(log_file))

def info_log_iter(iterable, logger):
    '''
    print every item in an iterable object to the log
    '''
    for item in iterable: logger.info(item)

def find_logger_basefilenames(logger):
    '''
    Finds the logger base filename(s)
    https://stackoverflow.com/a/7787832/5359531
    return a list of dicts, handler_name: filepath
    '''
    log_files = []
    # pf.my_debugger(locals().copy())
    for h in logger.__dict__['handlers']:
        if h.__class__.__name__ == 'FileHandler':
            name = h.get_name()
            file = h.baseFilename
            log_files.append({name: file})
    return(log_files)

def get_emaillog_filepath(logger):
    '''
    Get the path to the emaillog filehander output log file, from the logger object
    '''
    log_file = None
    for h in logger.__dict__['handlers']:
        if h.__class__.__name__ == 'FileHandler':
            name = h.get_name()
            if name == 'emaillog':
                log_file = h.baseFilename
    return(log_file)

def print_log_filenames(logger):
    '''
    Print out the filenames of the log files we're using
    '''
    log_files = find_logger_basefilenames(logger)
    for item in log_files:
        for key, value in item.items():
            logger.info("{0} log: {1}".format(key, value))

def log_setup(config_yaml, logger_name):
    '''
    Set up the logger for the script
    config = path to YAML config file
    '''
    # Config file relative to this file
    loggingConf = open(config_yaml, 'r')
    logging.config.dictConfig(yaml.load(loggingConf))
    loggingConf.close()
    return(logging.getLogger(logger_name))

def print_run_params(RunParametersXML):
    '''
    Print run params information from the RunParametersXML
    '''
    if os.path.exists(RunParametersXML):
        params_dict = parse_run_params_xml.make_params_dict(params_file = RunParametersXML)
        for key, value in params_dict.items():
            main.logger.info('{}: {}'.format(key, value))

def print_run_info(locations):
    '''
    Print info about the current run
    '''
    main.logger.info('Demultiplexing results for run: {0}'.format(locations.project_ID))

    print_run_params(locations.RunParametersXML)

    main.logger.debug('nextseq_dir: {0}'.format(locations.nextseq_dir))
    main.logger.info('run project_dir: {0}'.format(locations.project_dir))
    main.logger.debug('BaseCalls dir: {0}'.format(locations.basecalls_dir))
    main.logger.debug('Unaligned dir: {0}'.format(locations.unaligned_dir))

def find_file(filename, dir):
    '''
    Search a dir for a specific file
    use this for finding attachments; if the file cant be found something bad might have happened
    '''
    import fnmatch
    logger = logging.getLogger(main.logger_name)
    match = None
    if os.path.isdir(dir):
        for item in os.listdir(dir):
            item_path = os.path.join(dir, item)
            if os.path.isfile(item_path):
                if fnmatch.fnmatch(item, filename):
                    match = item_path
    if match == None:
        main.logger.warning("Could not find file '{0}' in dir: {1}".format(filename, dir))
    else:
        main.logger.debug("Found file: {0}".format(match))
    return(match)

def check_path_exists(path):
    '''
    Check that a filepath or dirpath exists
    use this for validations; if the files doesn't exist some error occured
    '''
    import os
    if not os.path.exists(path):
        main.logger.error("Path does not exist: {0}".format(path))
        return(False)
    else:
        return(True)

def validate_run(locations):
    '''
    Make sure the run meets criteria needed for emailing results; existence, completion, etc.
    '''
    import sys
    import os
    validations = []

    # run exists
    validations.append(check_path_exists(locations.project_dir))

    # RTAComplete.txt = basecalling finished
    validations.append(check_path_exists(os.path.join(locations.project_dir, "RTAComplete.txt")))

    # RunCompletionStatus.xml = run finished
    validations.append(check_path_exists(os.path.join(locations.project_dir, "RunCompletionStatus.xml")))

    # Demultiplex_Stats.htm = demultiplexing finished
    validations.append(check_path_exists(os.path.join(locations.unaligned_dir, "Demultiplex_Stats.htm")))

    # custom demultiplexing stats report generation
    validations.append(check_path_exists(locations.demultiplexing_stats_dir))
    validations.append(check_path_exists(locations.demultiplexing_stats_html))

    if not all(validations):
        main.logger.error("Errors were found while validating run; some items could not be found!")
    if all(validations):
        main.logger.info("The run passed all validations; all required items were found.")


def find_email_attachments(locations):
    '''
    Find all the files that we wish to email, if they are present
    '''
    desired_attachments = []
    # SampleSheet.csv
    desired_attachments.append(find_file(filename = "SampleSheet.csv", dir = locations.basecalls_dir))
    # RunParameters.xml
    desired_attachments.append(find_file(filename = "RunParameters.xml", dir = locations.project_dir))
    # new_demultiplexing_stats_file
    desired_attachments.append(find_file(filename = os.path.basename(locations.new_demultiplexing_stats_file), dir = os.path.dirname(locations.new_demultiplexing_stats_file)))
    # new_NextSeq_index_file
    desired_attachments.append(find_file(filename = os.path.basename(locations.new_NextSeq_index_file), dir = os.path.dirname(locations.new_NextSeq_index_file)))
    # demultiplexing_stats_html
    desired_attachments.append(find_file(filename = os.path.basename(locations.demultiplexing_stats_html), dir = os.path.dirname(locations.demultiplexing_stats_html)))

    email_attachments = []
    for item in desired_attachments:
        if item != None:
            email_attachments.append(item)
    return(email_attachments)

def log_copy(src, dest):
    '''
    Copy a file, and print a log message that we're doing it
    '''
    import shutil
    main.logger.debug("Copying {0} to {1}".format(src, dest))
    shutil.copy(src, dest)

def run_housekeeping(locations):
    '''
    Miscellaneous steps to take when prepping the run results for emailing
    '''
    # try to print the RTAComplete.txt file contents; timestamp of completion of basecalling
    if check_path_exists(os.path.join(locations.project_dir, "RTAComplete.txt")) == True:
        main.logger.info('File "RTAComplete.txt" found; basecalling completion information:')
        with open(os.path.join(locations.project_dir, "RTAComplete.txt"), 'r') as fin:
            main.logger.info(fin.read().strip())

    # make a copy of DemultiplexingStat HTML with run name
    demultiplexing_stats_file = os.path.join(locations.unaligned_dir, "Demultiplex_Stats.htm")
    new_demultiplexing_stats_file = os.path.join(locations.unaligned_dir, "{0}_{1}".format(locations.project_ID, os.path.basename(demultiplexing_stats_file)))
    log_copy(demultiplexing_stats_file, new_demultiplexing_stats_file)
    # add it to our locations
    locations.new_demultiplexing_stats_file = new_demultiplexing_stats_file

    # make a timestamped copy of the locations.NextSeq_index_file
    basename, ext = os.path.splitext(os.path.basename(locations.NextSeq_index_file))
    new_NextSeq_index_file = os.path.join(locations.unaligned_dir, '{0}_{1}{2}'.format(basename, timestamp, ext))
    log_copy(locations.NextSeq_index_file, new_NextSeq_index_file)
    locations.new_NextSeq_index_file = new_NextSeq_index_file


def get_recipient_list(demultiplexing_email_recipients_file):
    '''
    Get the email recipient list;
    tom@gmail.com, jane@gmail.com
    '''
    with open(demultiplexing_email_recipients_file, 'r') as f:
        for line in f:
            return(line.strip()) # only the first line

def get_server_address(email_server_address_file):
    '''
    Get the server address from the file;
    server.edu
    '''
    with open(email_server_address_file, 'r') as f:
        for line in f:
            return(line.strip()) # only the first line

def make_ssh_command():
    '''
    Set up the command needed to ssh back into the head node
    '''
    import getpass
    import settings
    username = getpass.getuser()
    email_server_address_file = settings.email_server_address_file
    server_address = get_server_address(email_server_address_file)
    ssh_command = 'ssh {0}@{1}'.format(username, server_address)
    return(ssh_command)


def email(locations):
    '''
    Find all the items needed and run the email commands
    '''
    # ~~~~~ MUTT SETUP ~~~~~ #
    # build the 'mutt' system command for sending the email
    # attachments
    email_attachments = find_email_attachments(locations)
    main.logger.debug('Email attachments:\n{0}'.format(email_attachments))

    # recipients
    recipient_list = get_recipient_list(locations.demultiplexing_email_recipients_file)
    recipient_list = "kellys04@nyumc.org" # debugging
    main.logger.debug('Email recipient list:\n{0}'.format(recipient_list))

    # subect
    subject_line = "[Demultiplexing] Results: NextSeq Run {0}".format(locations.project_ID)

    # mutt system comand
    mutt_command = mutt.mutt_mail(recipient_list = recipient_list, reply_to = '', subject_line = subject_line, message_file = get_emaillog_filepath(main.logger), attachment_files = email_attachments, return_only_mode = True, quiet = True)


    # ~~~~~ ssh SETUP ~~~~~ #
    # mutt is only installed on the head node so we need to ssh back into the head node
    # in order to run the mutt command
    ssh_command = make_ssh_command()

    # ~~~~~ SEND EMAIL ~~~~~ #
    final_command = '''
{0} <<E0F2
{1}
E0F2
'''.format(ssh_command, mutt_command)
    main.logger.debug('Email command is:\n{0}\n\n'.format(final_command))
    pf.subprocess_cmd(command = final_command)



def main(project_ID):
    '''
    Main control function for the program
    '''
    # get locations for dirs for the run
    locations = get_locations(project_ID = project_ID)

    # ~~~~~ LOGGING SETUP ~~~~~ #
    # set items for the log setup
    scriptdir = os.path.dirname(os.path.realpath(__file__))
    config_yaml = os.path.join(scriptdir,'logging.yml')
    logger_name = 'mail_demultiplexing_results'

    # set some main attributes for the get_logpath_values functions
    main.project_ID = project_ID
    main.auto_demultiplex_log_dir = locations.auto_demultiplex_log_dir

    # logger to use from the config file
    main.logger_name = 'mail_demultiplexing_results'

    # the 'global' logger object to use throughout the script
    main.logger = log_setup(config_yaml = config_yaml, logger_name = logger_name)

    # ~~~~~ PROCESS RUN ~~~~~ #
    print_run_info(locations)

    # log the paths to the logs in the logs
    print_log_filenames(logger = main.logger)

    validate_run(locations)
    run_housekeeping(locations)

    # ~~~~~ EMAIL ~~~~~ #
    email(locations)


def run():
    '''
    Run the program from the command line
    arg parsing goes here, if program was run as a script
    '''
    import argparse
    # ~~~~ GET SCRIPT ARGS ~~~~~~ #
    parser = argparse.ArgumentParser(description='Demultiplexing results email script')

    parser.add_argument("project_IDs", type = str,  nargs='*', help="IDs of the NextSeq run(s) to be emailed") # nargs='+' #

    args = parser.parse_args()

    project_IDs = args.project_IDs

    for project_ID in project_IDs:
        main(project_ID = project_ID)

# ~~~~ GLOBALS ~~~~~~ #
timestamp = pf.timestamp()

if __name__ == "__main__":
    run()
