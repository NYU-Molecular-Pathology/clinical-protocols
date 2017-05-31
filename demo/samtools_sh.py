#!/usr/bin/env python

'''
This demo script will show how to use 'sh' to access system installed tools that require
environment setup with 'module'
'''

def mkdirs(path, return_path=False):
    '''
    Make a directory, and all parent dir's in the path
    '''
    import sys
    import os
    import errno
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise
    if return_path:
        return path


def samtools_bowtie_sh_env():
    '''
    Return the environment needed to load samtools and bowtie with 'sh'
    '''
    import sh
    import json
    env_output = sh.bash("-c", """
    module unload gcc > /dev/null 2>&1
    module unload samtools > /dev/null 2>&1
    module load samtools/1.2.1 > /dev/null 2>&1
    module load bowtie2/2.2.6 > /dev/null 2>&1
    python -c 'import json, os;print(json.dumps(dict(os.environ)))'
""")
    env = json.loads(str(env_output))
    return(env)


def align():
    '''
    Fastq read alignment with bowtie2
    equivalent to: bowtie2 --threads "$THREADS" --local -x "$tmpGenome" -q -U "$INPUTFILE" | samtools view -@ "$THREADS" -Sb1 - | samtools sort -m 10G -@ "$THREADS" - "$OUTFILE"
    '''
    import json
    import sh
    env = samtools_bowtie_sh_env()
    sh_align = sh(_env = env)
    from sh_align import bowtie2
    from sh_align import samtools
    input_fastq = "input/test2.fastq"
    output_bam = "output/test2.bam"
    threads = 1
    # genome = "/Users/steve/ref/iGenomes/Homo_sapiens/UCSC/hg19/Sequence/Bowtie2Index/genome"
    # "/local/data/iGenomes/Homo_sapiens/UCSC/hg19/Sequence/WholeGenomeFasta/genome.fa"
    genome = "/local/data/iGenomes/Homo_sapiens/UCSC/hg19/Sequence/Bowtie2Index/genome"
    memory = "2G"
    samtools_threads = "-@ {0}".format(threads)
    mkdirs("output")
    # print(bowtie2("--version"))
    print(samtools.sort(samtools.view(bowtie2("-q", "--local", threads = threads,  x = genome, U = input_fastq, _env = env), "-Sb1", samtools_threads ), samtools_threads, m = memory, _out= output_bam) )

align()
