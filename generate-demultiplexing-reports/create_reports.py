#!/usr/bin/env python
# tested with python 2.7

import os
import settings


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

def print_iter(iterable):
    '''
    basic printing of every item in an iterable object
    '''
    for item in iterable: print(item)

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

def print_div():
    '''
    prints a divider
    '''
    div = '------------------------------'
    print('\n{0}\n'.format(div))

def validate_run_dir(run_dir):
    '''
    Determine if a sequecning run has been demultiplexed
    '''
    is_valid = [] # will hold booleans
    report_dir = "Data/Intensities/BaseCalls/Unaligned/Reports"
    report_html_dir = "Data/Intensities/BaseCalls/Unaligned/Reports/html"
    stats_dir = "Data/Intensities/BaseCalls/Unaligned/Stats"
    demult_stats_xml = "Data/Intensities/BaseCalls/Unaligned/Stats/DemultiplexingStats.xml"

    # make sure required dirs exit
    for item in [report_dir, report_html_dir, stats_dir]:
        item_path = os.path.join(run_dir, item)
        if os.path.isdir(item_path):
            is_valid.append(True)
        else:
            is_valid.append(False)

    # make sure required files exit
    if os.path.isfile(os.path.join(run_dir, demult_stats_xml)):
        is_valid.append(True)
    else:
        is_valid.append(False)

    # skip runs I added as tests
    bad_suffixes = ["test", "test1", "_run_before_sequencing_done", "_test_sequencing_finished", "ArcherRun"]
    for suffix in bad_suffixes:
        if run_dir.endswith(suffix):
            is_valid.append(False)

    validation = all(is_valid)

    print("{0}: {1}".format(validation, run_dir))
    return(validation)


def find_demultiplexing_report_HTML(demultiplexing_stats_outdir, run_ID):
    '''
    Get the full path to the output HTML report output
    '''
    match = None
    if os.path.isdir(demultiplexing_stats_outdir):
        for file in os.listdir(demultiplexing_stats_outdir):
            if os.path.isfile(os.path.join(demultiplexing_stats_outdir,file)):
                if file.endswith("demultiplexing_report.html"):
                    if file.startswith(run_ID):
                        match = os.path.abspath(os.path.join(demultiplexing_stats_outdir,file))
    else:
        print("Dir does not exist: {0}".format(demultiplexing_stats_outdir))
    return(match)

def create_demultiplexing_report(run_dir):
    '''
    Run the commands needed to genereate the demultiplexing report
    '''
    print_div()
    run_ID = os.path.basename(run_dir)
    unaligned_dir = "Data/Intensities/BaseCalls/Unaligned" # output subdir for demultiplexing
    run_unaligned_dir = os.path.join(run_dir, unaligned_dir)
    demultiplexing_stats_sourcedir = "/ifs/data/molecpathlab/scripts/demultiplexing-stats"
    demultiplexing_stats_outdir = os.path.join(run_unaligned_dir, "demultiplexing-stats")
    local_link_dir = "reports"

    print("Running report generation steps for run: {0}".format(run_ID))
    print("run_unaligned_dir: {0}".format(run_unaligned_dir))
    print("demultiplexing_stats_outdir: {0}".format(demultiplexing_stats_outdir))


    # system command for copying report template code over
    rsync_command = '''
rsync -vrhPtr "{0}/" "{1}/"
'''.format(demultiplexing_stats_sourcedir, demultiplexing_stats_outdir)

    full_command = '''
set -x

[ -d "{1}" ] && rm -rf "{1}"

mkdir "{1}"

if [ -d "{1}" ]; then
    {0}

    cd {1}
    bash ./run.sh "{2}" "{3}"
else
    printf "ERROR: could not change to desired output dir"
fi

'''.format(rsync_command, demultiplexing_stats_outdir, run_unaligned_dir, run_ID)



    # check if the report has been generated already; run if the command if it doesn't exit
    print("checking for previous report output...")
    html_output = find_demultiplexing_report_HTML(demultiplexing_stats_outdir, run_ID)
    print("results found: {0}".format(html_output))
    if html_output == None:
        print("Previous report output not found. Running command:\n{0}\n\n".format(full_command))
        # run the command
        subprocess_cmd(full_command)
    else:
        print("Previous report results found, skipping report generation step")

    # check again for the HTML output now
    # make symlink in the reports dir
    print("checking again for (new) report output...")
    html_output = find_demultiplexing_report_HTML(demultiplexing_stats_outdir, run_ID)
    print("results found: {0}".format(html_output))
    if html_output != None:
        html_symlink = os.path.join(local_link_dir, os.path.basename(html_output))
        print("Checking if symlink needs to be made to the report output; link will be: {0}".format(html_symlink))
        if not os.path.exists(html_symlink):
            print("Symlink does not exit. Creating link from {0} to {1}".format(html_output, html_symlink))
            os.symlink(html_output, html_symlink)
        else:
            print("Symlink already exists, skipping.")
    print_div()

def main():
    '''
    Main control function for the program
    '''
    # location for sequencing output
    nextseq_dir = settings.nextseq_dir
    print("location for sequencing output:\n{0}\n\n".format(nextseq_dir))

    print_div()

    # find all subdirs
    print("finding all subdirs...")
    run_dirs = [os.path.join(nextseq_dir, item) for item in os.listdir(nextseq_dir) if os.path.isdir(os.path.join(nextseq_dir, item))]
    print("subdirs found:")
    print_iter(run_dirs)

    print_div()

    print("validating run dirs...")
    valid_dirs = []
    for run_dir in run_dirs:
        validation = validate_run_dir(run_dir)
        if validation == True:
            valid_dirs.append(run_dir)

    print_div()

    print("valid dirs found:")
    print_iter(valid_dirs)

    print_div()

    print("creating reports...")
    for valid_dir in valid_dirs:
        create_demultiplexing_report(valid_dir)

def run():
    '''
    Run the monitoring program
    arg parsing goes here, if program was run as a script
    '''
    main()


if __name__ == "__main__":
    run()
