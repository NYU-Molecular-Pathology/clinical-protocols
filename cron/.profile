# profile to use for cron jobs on NYULMC phoenix compute cluster
# copy/pasted from the profile files I have set already


# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi


module load python/2.7
module unload git
module load git/2.6.5
module unload r/3.0.2
module load r/3.3.0

# for my vim
[ -d "${HOME}/bin" ] && export PATH=${HOME}/bin:$PATH
[ -d "${HOME}/share" ] && export PATH=${HOME}/share:$PATH


export PATH=$PATH:/ifs/home/at570/disk1/Resources/Bin/linux
export PATH=$PATH:/ifs/home/kellys04/software
export PYTHONPATH="${PYTHONPATH}:/ifs/home/kellys04/software/python"
export PYTHONPATH=$PYTHONPATH:/ifs/home/kellys04/.local/lib/python2.7/site-packages
export PYTHONPATH=$PYTHONPATH:~/ansible/lib/


export MANPATH=:/cm/shared/apps/sge/2011.11p1/man:ignore:/cm/local/apps/environment-modules/3.2.6/man
export PERL5LIB=$HOME/software/czplib.v1.0.6


export PATH=$PATH:/ifs/home/kellys04/software/bin
export PATH=$PATH:/ifs/home/kellys04/software/UCSC
export PATH=$PATH:/ifs/home/kellys04/software/annovar
export PATH=$PATH:/ifs/home/kellys04/software/vcflib

export PATH=$PATH:/ifs/home/kellys04/.local/lib/python2.7/site-packages
export PATH=$PATH:~/ansible/bin/


