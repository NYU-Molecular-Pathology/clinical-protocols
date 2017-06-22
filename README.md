# protocols
## Protocols for clinical analysis are in the [wiki](https://github.com/NYU-Molecular-Pathology/protocols/wiki)

-----

# Descriptions
## Directories
(excluding submodules)
- `NGS580`: scripts used for NGS580 gene panel analysis
- `bin_scripts`: misc scripts and config files used to set up the `bin` directory (not included in repo) with installed software and packages needed for analysis
- `cron`: scripts and items used for automating tasks with `cron`
- `demo`: misc scripts used to demonstrate programming techniques for use elsewhere
- `demultiplexing`: scripts used for demultiplexing of NGS data
- `generate-demultiplexing-reports`: script & location for generation of demultiplexing reports for all runs in the NextSeq directory
- `misc`: scripts that don't fall into any other category
- `reference-manuals`: important user manuals needed for reference
- `samplesheets`: examle sample sheets used for analysis

## Files
- `bash_functions.sh`: common set of functions used in various bash scripts
- `bash_settings.sh`: settings used by bash scripts
- `example.email_recipients.txt`: an example of what the `email_recipients.txt` file should look like for use in email scripts
- `python_functions.py`: common set of functions used in various Python scripts
- `sequencer_settings.json`: Select settings saved in JSON format for use with certain Python scripts
- `settings`: simple text file containing locations to scripts and directories, formatted for use with both Python and bash scripts
- `template.py`: template Python script

## Submodules
- `IGV-snapshot-automator`: Use for making IGV snapshots
- `demultiplexing-stats`: Demultiplexing stats report for use with NextSeq
- `run-monitor`: (In development); Program for automatic monitoring of lab devices for processing of new data
- `sh`: Python module for easier access to system programs from within Python
- `sns`: NGS analysis pipeline customized for use on HPC cluster at NYUMC
- `sns-wes-coverage-analysis`: First-step analysis of coverage data output by `sns` pipeline
- `sns-wes-downstream-analysis`: Further post-processing of `sns` variant calling pipeline output
- `toolbox`: Utility scripts
