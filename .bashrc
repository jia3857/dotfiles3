# filename: ~/.bashrc
#
#

## Non-interactive shell check
if [[ $- != *i* ]]; then
    return
fi

echo "$HOME/.bashrc"
echo "\$- = $-"

## install DEBUG trap
trap 'printf "\e[0m" "$_"' DEBUG

## DETECT OS
if [ "$(uname -s)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    export PATH="/usr/local/Cellar/mysql/5.7.12/bin:$PATH"
    # export PYTHONPATH="/Library/Python/2.7/site-packages:$PYTHONPATH"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    _OS="linux"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under Windows NT platform
    _OS="cygwin"
fi

## Nice handy bash function
rtfm() { $@ --help 2> /dev/null || man $@ 2> /dev/null || open "http://www.google.com/search?q=$@"; }
alias pass="cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10| head -n 4"
alias passlong="cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 18| head -n 4"
alias nocomment='egrep -v "^\s*(#|$)"'
alias youtube-dl-playlist="youtube-dl --continue --no-overwrites --ignore-errors --output '%(playlist)s/%(playlist_index)s- %(title)s.%(ext)s'"
alias youtube-dl-mp3='youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0  --add-metadata'
function youtube-dl-x {
    local url=$1
    youtube-dl -x --postprocessor-args "-ss 00:12:44.00 -t 00:01:33.00" $url
}

function sshc() {
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $1
}

function my-etags() {
    set -x
    if [ -n "$1" ]; then
	base=$1; shift
    else
	base=$PWD
    fi
    find "$base" -name '*.py' -o -name '*.c' -o -name '*.cpp' -o -name '*.h' | xargs etags -o "$base/TAGS"
    set +x
}

# git prompt and git autocomplete
function _git_autocomplete() {
  [ -f /usr/share/git/completion/git-prompt.sh ] && source /usr/share/git/completion/git-prompt.sh

  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
  fi
}

# hadoop autocomplete
function _hadoop_autocomplete() {
    local SRC="https://raw.githubusercontent.com/guozheng/hadoop-completion/master/hadoop-completion.sh"
    local TARGET=~/bin/bash_completion.d
    if [ ! -d ${TARGET} ]; then
	mkdir -p ${TARGET}
    fi
    curl ${SRC} -so ${TARGET}/hadoop-completion.sh && chmod +x ${TARGET}/hadoop-completion.sh
    source ${TARGET}/hadoop-completion.sh
}
_hadoop_autocomplete

function _cloudera_scm_info {
    files=("/usr/share/cmf/cloudera/cm_version.properties")
    for f in "${files[@]}"; do
	if [ -f $f ]; then
	    echo ==== $f ====
	    cat $f
	fi
    done
}

function _scm_info(){
    grep '^version=' /usr/share/cmf/cloudera/cm_version.properties
}

colors() {
    local fgc bgc vals seq0

    printf "Color escapes are %s\n" '\e[${value};...;${value}m'
    printf "Values 30..37 are \e[33mforeground colors\e[m\n"
    printf "Values 40..47 are \e[43mbackground colors\e[m\n"
    printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

    # foreground colors
    for fgc in {30..37}; do
	# background colors
	for bgc in {40..47}; do
	    fgc=${fgc#37} # white
	    bgc=${bgc#40} # black

	    vals="${fgc:+$fgc;}${bgc}"
	    vals=${vals%%;}

	    seq0="${vals:+\e[${vals}m}"
	    printf "  %-9s" "${seq0:-(default)}"
	    printf " ${seq0}TEXT\e[m"
	    printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
	    done
	echo; echo
	done
}

set_prompt () {
    Last_Command=$? # Must come first!
    Blue='\[\e[01;34m\]'
    White='\[\e[01;37m\]'
    Red='\[\e[01;31m\]'
    Green='\[\e[01;32m\]'
    Reset='\[\e[00m\]'
    FancyX='\342\234\227'
    Checkmark='\342\234\223'

    # Add a bright white exit status for the last command
    PS1="$White\$? "
    # If it was successful, print a green check mark. Otherwise, print
    # a red X.
    if [[ $Last_Command == 0 ]]; then
        PS1+="$Green$Checkmark "
    else
        PS1+="$Red$FancyX "
    fi
    # If root, just print the host in red. Otherwise, print the current user
    # and host in green.
    if [[ $EUID == 0 ]]; then
        PS1+="$Red\\h "
    else
        PS1+="$Green\\u@\\h "
    fi
    # Print the working directory and prompt marker in blue, and reset
    # the text color to the default.
    PS1+="$Blue\\w \\\$$Reset "
}
# PROMPT_COMMAND='set_prompt'


####
#### cloudera
####

_cdep_list_group() {
    pushd .
    cd ~/work/deploy/cdep
    source target/env/bin/activate
    echo ">>> \$HOSTS = $HOSTS"

    local USER=$1

    declare -a cloud=("EC2" "GCE" "AZURE")

    for c in "${cloud[@]}"; do
	echo ">>>> cloud-type: $cloud"
	cmd="./infrastructure/cloudcat.py --username=jjyeh list_groups --cloud-type=$c"
	if [[ x"" != x"$USER" ]]; then
	    cmd+=" --user=${USER}"
	fi
	echo ">>>> $cmd "
	$cmd
    done
    popd
}

_find_java() {
    JPATH=$(dirname `find /usr|grep -E jps$`)
    echo "JAVA BIN PATH: $JPATH"
    export PATH=$JPATH:$PATH
}

_cdep_resource() {
    cd ~/work/deploy/cdep
    source target/env/bin/activate
    echo ">>> \$HOSTS = $HOSTS"
    cmd1="./resources.py -a 'nightly-{1..4}.vpc.cloudera.com' --resource=cm_repo,cm570 get_resource_info"
    cmd2="./resources.py -a 'nightly-{1..4}.vpc.cloudera.com' --resource=cdh_repo,cdh570 get_resource_info"
    echo $cmd1
    $cmd1
    echo $cmd2
    $cmd2
}

_cdep_provision() {
    [ -z $1 ] && echo "ERROR: NO \$HOSTS defined" && return 1
    echo "..HOSTS = ${HOSTS}"
    export HOSTS=$1
    #cd ~/work/systest/systest
    cd ~/work/deploy/cdep
    ./infrastructure/cloudcat.py --username=`whoami` list_groups
    set -x
    ./infrastructure/cloudcat.py --hosts="$HOSTS" --os=centos71 --expiration-days=0 --expiration-hours=32 --username=jjyeh --master-size=2xlarge --slave-size=large create_group
    set +x
}

_cdep_destroy() {
    local HOSTS=$@
    [[ -z ${HOSTS} ]] && echo "need 'jjyeh-s12-{1..4}.vpc.cloudera.com' as argument"
    cd ~/work/deploy/cdep
    ./infrastructure/cloudcat.py  --username=jjyeh --hosts="$HOSTS" destroy_group
}

_cdep_resume() {
    local HOSTS=$@
    [[ -z ${HOSTS} ]] && echo "need 'jjyeh-s12-{1..4}.vpc.cloudera.com' as argument"
    cd ~/work/deploy/cdep
    ./infrastructure/cloudcat.py  --username=jjyeh --hosts="$HOSTS" resume_group
}

_cdep_extend() {
    local HOSTS=$1
    local USER=$2
    [[ -z ${HOSTS} ]] && echo "need 'jjyeh-s12-{1..4}.vpc.cloudera.com' as argument"
    cd ~/work/deploy/cdep
    ./infrastructure/cloudcat.py  --hosts=${HOSTS} --username=${USER} --expiration-days=1 extend_group
}
_cdep_sysadmin() {
    [ -z $1 ] && echo "ERROR: NO \$HOSTS defined" && return 1
    echo "..HOSTS = ${HOSTS}"
    export HOSTS=$1
    #cd ~/work/systest/systest
    cd ~/work/deploy/cdep
    ./sysadmin.py --agents="$HOSTS" --require-examples --version=master --include-service=ZOOKEEPER,HDFS,YARN,MAPREDUCE,HIVE,IMPALA,HUE clean setup
}

_systest_pre() {
    cd ~/work/systest/systest
    source target/env/bin/activate
    echo ">>> \$HOSTS = $HOSTS"
    echo "examples:"
    echo "  ./target/env/bin/cdep_cloudcat --user=jjyeh --cloud-type GCE list_groups"
    echo "  ./systest.py -a 'cdh570@nightly-{1..4}.gce.cloudera.com' -v master --no-lock dump_databases"
    echo "  ./systest.py -a \"cdh580@$HOSTS\" -V --no-locks -v master --no-support-bundles --scale-test-duration=10m -n scale.tests.test_stage_hive_impala:HiveImpalaDataStage.test_ingest_hive_impala_tpcds_data run_tests"
}

_systest_build() {
    SKIP_MAVEN=1 make clean install
}

_hadoop_benchmark() {
    HADOOP_PATH=/opt/cloudera/parcels/CDH/lib/hadoop-0.20-mapreduce
    RESULTS_D=/results
    if [ ! -d $HADOOP_PATH ]; then
	echo "no HADOOP DIR: $/opt/cloudera/parcels/CDH/lib/hadoop-0.20-mapreduce"
	return 1
    fi

    if [ ! -d $RESULTS_D ]; then
	echo "no RESULTS DIR: $RESULTS_D"
	mkdir -p $RESULTS_D
    fi

    for i in 2 4 8 16 32 64 # Number of mapper containers to test
    do
        for j in 2 4 8 16 32 64 # Number of reducer containers to test
        do
            for k in 1024 2048 # Container memory for mappers/reducers to test
            do
		echo "==== test ==== i: $i, j: $j, k: $k"
                MAP_MB=`echo "($k*0.8)/1" | bc` # JVM heap size for mappers
                RED_MB=`echo "($k*0.8)/1" | bc` # JVM heap size for reducers
                hadoop jar $HADOOP_PATH/hadoop-examples.jar teragen \
                -Dmapreduce.job.maps=$i -Dmapreduce.map.memory.mb=$k \
                -Dmapreduce.map.java.opts.max.heap=$MAP_MB 100000000 \
                $RESULTS_D/tg-10GB-${i}-${j}-${k} 1>$RESULTS_D/tera_${i}_${j}_${k}.out 2>$RESULTS_D/tera_${i}_${j}_${k}.err

    	        hadoop jar $HADOOP_PATH/hadoop-examples.jar terasort \
                -Dmapreduce.job.maps=$i -Dmapreduce.job.reduces=$j -Dmapreduce.map.memory.mb=$k \
                -Dmapreduce.map.java.opts.max.heap=$MAP_MB -Dmapreduce.reduce.memory.mb=$k \
                -Dmapreduce.reduce.java.opts.max.heap=$RED_MB $$RESULTS_D/ts-10GB-${i}-${j}-${k} \
                1>>$RESULTS_D/tera_${i}_${j}_${k}.out 2>>$RESULTS_D/tera_${i}_${j}_${k}.err

	        hadoop fs -rmr -skipTrash $RESULTS_D/tg-10GB-${i}-${j}-${k}
                hadoop fs -rmr -skipTrash $RESULTS_D/ts-10GB-${i}-${j}-${k}
            done
        done
    done
}

_docker_search() {
    WS=~/WORK
    if [ -z $1 ]; then
	return 1
    fi
    [[ ! -d $WS ]] && mkdir $WS
    echo "search strings: $@"
    pushd .
    cd $WS
    if [ ! -d docker_registry_cli ]; then
	git clone https://github.com/vivekjuneja/docker_registry_cli
    fi
    cd docker_registry_cli
    # python browser.py docker-registry.infra.cloudera.com list all ssl
    python browser.py docker-registry.infra.cloudera.com search $1 ssl
    popd
}

git-prompt1() {
    file_location="~/git-prompt.sh"
    rm -f ${file_location}
    (cd ~; wget -q https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh)
    source ~/git-prompt.sh
    #PROMPT_COMMAND='__git_ps1 "\u@\h:\w" "\\\$ "'
    PROMPT_COMMAND='__git_ps1 "\u@\h:\w ($?)" "\n\\\$ "'
}

git-prompt2() {
    GIT_BIN=$(which git 2>/dev/null)
    if [ ! -f ${GIT_BIN} ]; then
        log $wrn_lvl "!!!! no git installed"
	return 1
    fi
    if [ ! -d $HOME/.bash-git-prompt ]; then
	rm -rf ~/.bash-git-prompt/
	(cd ~; git clone https://github.com/magicmonty/bash-git-prompt .bash-git-prompt --depth=1)
    fi
    export GIT_PROMPT_THEME="Custom"
    source ~/.bash-git-prompt/gitprompt.sh
    export GIT_PROMPT_ONLY_IN_REPO=1
    #export GIT_PROMPT_END_USER=" ${White}[${USER}@${HOSTNAME%%.*}]\n$(date +%H:%M)${ResetColor} $ "
    export GIT_PROMPT_END_USER="\n${Green}${USER}${ResetColor}@${Blue}${HOSTNAME%%.*}${ResetColor}${ResetColor} $ "
    GIT_PROMPT_THEME="Custom"
}

function prompt_callback {
    if [ `jobs | wc -l` -ne 0 ]; then
        echo -n " jobs:\j"
    fi
}

#!/bin/bash

##
## Simple logging mechanism for Bash
##
## Author: Michael Wayne Goodman <goodman.m.w@gmail.com>
## Thanks: Jul for the idea to add a datestring. See:
## http://www.goodmami.org/2011/07/simple-logging-in-bash-scripts/#comment-5854
## Thanks: @gffhcks for noting that inf() and debug() should be swapped,
##         and that critical() used $2 instead of $1
##
## License: Public domain; do as you wish
##

exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=3 # default to show warnings
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5

notify() { log $silent_lvl "NOTE: $1"; } # Always prints
critical() { log $crt_lvl "CRITICAL: $1"; }
error() { log $err_lvl "ERROR: $1"; }
warn() { log $wrn_lvl "WARNING: $1"; }
inf() { log $inf_lvl "INFO: $1"; } # "info" is already a command
debug() { log $dbg_lvl "DEBUG: $1"; }
log() {
    if [ $verbosity -ge $1 ]; then
        datestring=`date +'%Y-%m-%d %H:%M:%S'`
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        echo -e "    $datestring $2" | fold -w70 -s | sed '2~1s/^/  /' >&3
    fi
}

show-handy-functions() {
    set | egrep '^[_a-zA-Z].+\ \(\)'
}

#alias git-prompt=git-prompt1
alias git-prompt=git-prompt2
git-prompt
# show-handy-functions
export PYTHONWARNINGS="ignore"

# https://medium.com/toutsbrasil/how-to-manage-your-dotfiles-with-git-f7aeed8adf8b
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'