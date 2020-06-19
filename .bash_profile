# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:/usr/local/bin:$PATH";

# Prompt
export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h: \[\e[33m\]\w\[\e[0m\]\n\$ '

# Bash History
export PROMPT_COMMAND='if [ "$(id -u)" -ne 0 ]; then echo "$(date "+%Y-%m-%d_%H:%M:%S") $(pwd) $(history 1)" >> ~/.logs/bash-history-$(date "+%Y-%m-%d").log; fi'

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
    [ -f $file ] && echo "source $file" && source $file;
done
for file in ~/.{path,exports,aliases,functions,extra}; do
    if \curl -I -s -L https://raw.githubusercontent.com/jia3857/dotfiles/master/${file##*/} | head -1 | grep "HTTP/1.1 404 Not Found" 2>&1 1> /dev/null ; then
        # continue
        break
    else
        \curl -I -s -L https://raw.githubusercontent.com/jia3857/dotfiles/master/${file##*/}
        [ $? -eq 0 ] && [ -r "$file" ] && [ -f "$file" ] && source "$file";
    fi
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# NVM YARN
export NVM_DIR="$HOME/.nvm"
export NVM_SCRIPT="/usr/local/opt/nvm/nvm.sh"
if [ -f $NVM_SCRIPT ]; then
    . $NVM_SCRIPT
fi

function my_cdiff {
    colordiff -u "$@" | less -RF
}

function tc_exec() { "$@" | ts '[%Y-%m-%d %H:%M:%S]'; }

# My SSH
alias sshr=my_ssh_retry_wrapper

function my_ssh_retry_wrapper {
        if [ -z "$1" ]; then
      echo '' && echo 'Please also provide server name as in config file...' &&
      exit 1
    fi

    retries=0
    repeat=true
    today=$(date)

    while "$repeat"; do
      ((retries+=1)) &&
      echo "[`date '+%Y-%m-%d %H:%M:%S'`] Try number $retries..." &&
      today=$(date) &&
      ssh "$@" &&
      repeat=false
      if "$repeat"; then
        sleep 5
      fi
    done

    echo "Total number of tries: $retries"
    echo "Last connection at: $today"
}

#### Bash completion for many commands
HOMEBREW_PREFIX=$(brew --prefix)
if type brew &>/dev/null; then
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      [[ -r "$COMPLETION" ]] && source "$COMPLETION"
    done
  fi
fi

# docker
if hash docker 2> /dev/null; then
  curl -sqXGET https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker > $(brew --prefix 2>/dev/null)/etc/bash_completion.d/docker
  source <(curl -qs https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker)
fi

# git bash completion
if hash git 2> /dev/null; then
    if [ $(uname -s) = "Darwin" ]; then
        [ ! -f /usr/local/share/bash-completion/bash_completion ] \
            && [ $BASH_VERSION > 4 ] && brew install bash-completion@2
        . /usr/local/share/bash-completion/bash_completion
    fi
    source <(curl -qs https://raw.githubusercontent.com/git/git/v2.17.1/contrib/completion/git-completion.bash)
    echo "[git] bash completion loaded"
fi
# git grep + blame
ggb() { git grep -n "$1" | while IFS=: read i j k; do git blame -c -f -L $j,$j $i; done }
geb() {
    git grep -E -n $1 | while IFS=: read i j k; do git blame -L $j,$j $i | cat; done
}

gdiff() {
    git difftool -y -x "sdiff -w $(tput cols)" "${@}" | less
}

gyd() {
    ydiff -ls -w 0 --wrap "${@}"
}

# awscli
awsls () {
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,Tags[?Key==`Name`].Value[]]' --output json | tr -d '\n[] "' | perl -pe 's/i-/\ni-/g' | tr ',' '\t' | sed -e 's/null/None/g' | grep '^i-' | column -t
}

if hash aws_completer; then
    complete -C $(which aws_completer) aws
fi

# vagrant completion
if command -v vagrant >/dev/null 2>&1 || { echo >&2 "No vagrant installed, skip vagrant bash completion"; }; then
    case $(uname -s) in
    *Darwin*)
        [ -f `brew --prefix`/etc/bash_completion.d/vagrant ] && source `brew --prefix`/etc/bash_completion.d/vagrant ;;
    *)
        source <(curl -qs https://raw.githubusercontent.com/hashicorp/vagrant/master/contrib/bash/completion.sh)
    esac
    echo "[vagrant] bash completion loaded"
fi

# perf bash completion
if hash perf 2> /dev/null; then
    source <(curl -sq https://raw.githubusercontent.com/torvalds/linux/master/tools/perf/perf-completion.sh)
    echo "[perf] bash completion loaded, you can try:"
    echo "  \$ perf list # list all events"
    echo "  \$ perf record -e block:block_rq_issue -ag"
    echo "  \$ ls -l perf.data"
    echo "  \$ perf report"
fi

# kubectl bash completion
if hash kubectl 2> /dev/null; then
    source <(kubectl completion bash)
    echo "[kubectl] bash completion loaded"
fi

if [ "${BASH-no}" != "no" ]; then
         [ -r ~/.bashrc ] && . ~/.bashrc
fi

# compile readline (libreadline.a) on Mac Mojave
if [[ $(uname -s) == "Darwin" ]]; then
    # Download xcode commandline tools
    # xcode-select --install
    # open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg --or--
    # sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
    # export "CFLAGS=-I/usr/local/include -L/usr/local/lib"
    # ------------------------------------------------------------------------
    # https://github.com/RustAudio/coreaudio-sys/issues/21
    # sudo xcode-select -switch /
    # find / 2> /dev/null | grep MacOSX10.14.sdk
    export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX10.14.sdk/usr/include"
fi

#### My handy functions ####
# git grep + blame
ggb() { git grep -n "$1" | while IFS=: read i j k; do git blame -c -f -L $j,$j $i; done }
geb() {
    git grep -E -n $1 | while IFS=: read i j k; do git blame -L $j,$j $i | cat; done
}

# awscli
awsls () {
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,Tags[?Key==`Name`].Value[]]' --output json | tr -d '\n[] "' | perl -pe 's/i-/\ni-/g' | tr ',' '\t' | sed -e 's/null/None/g' | grep '^i-' | column -t
}

# ssh-agent forward
fixssh() {
    if tmux -V | grep 1.8 ; then
        eval $(tmux show-env | sed -n 's/^\(SSH_[^=]*\)=\(.*\)/export \1="\2"/p');
        eval $(tmux show-env | sed -n 's/^\(DISPLAY[^=]*\)=\(.*\)/export \1="\2"/p')
    else
        eval $(tmux show-env -s |grep '^SSH_')
        eval $(tmux show-env -s |grep '^DISPLAY')
    fi
}

# k8s debug
_my_k8s_save_cluster() {
    local SAVE_DIR=${HOME}/clusterstate/
    kubectl cluster-info dump --all-namespaces --output-directory=${SAVE_DIR} -o yaml
    ls -lrt ${SAVE_DIR}
}

_my_k8s_save_yaml() {
local ADVANCED=${ADVANCED:-"true"}

if [ -z "${ADVANCED}" ]; then
    for n in $(kubectl get -o=name pvc,configmap,serviceaccount,secret,ingress,service,deployment,statefulset,hpa,job,cronjob); do
        mkdir -p $(dirname $n);
        # kubectl get -o=yaml --export $n > $n.yaml;
        kubectl get -o=yaml $n > $n.yaml;
    done
else
    for n in $(kubectl get -o=name pvc,configmap,ingress,service,secret,deployment,statefulset,hpa,job,cronjob | grep -v 'secret/default-token'); do
        #kubectl get -o=yaml --export $n > $(dirname $n)_$(basename $n).yaml
        kubectl get -o=yaml $n > $(dirname $n)_$(basename $n).yaml
    done
fi
}

_my_k8s_netshoot() {
  set -x
  local args=$@
  kubectl run -i -t --restart=Never --rm \
    netshoot --image=nicolaka/netshoot \
    ${args} \
    -- /bin/bash
  set +x
}

_my_k8s_netshoot_hostNetwork() {
  if type _k8s_netshoot; then
    _k8s_netshoot --overrides='{"kind":"Pod", "apiVersion":"v1", "spec": {"hostNetwork": true}}'
  fi
}

_my_k8s_debug() {
  local tempDir=$(mktemp -d /tmp/tmp.XXXX)
  local arch=$(uname)
  trap "{ rm -rf $tempDir; }" EXIT

  pushd . ; cd ${tempDir}
  export PLUGIN_VERSION=0.1.1
  case "$arch" in
  Linux )  # linux x86_64
    curl -sLo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v${PLUGIN_VERSION}/kubectl-debug_${PLUGIN_VERSION}_linux_amd64.tar.gz
    ;;
  Darwin ) # macos
    curl -sLo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v${PLUGIN_VERSION}/kubectl-debug_${PLUGIN_VERSION}_darwin_amd64.tar.gz
    ;;
  esac
  tar -zxvf kubectl-debug.tar.gz kubectl-debug
  sudo mv kubectl-debug /usr/local/bin/
  popd
}

_my_k8s_sniff() {
  (
    set -x; cd "$(mktemp -d)" &&
    curl -fsSLO "https://storage.googleapis.com/krew/v0.2.1/krew.{tar.gz,yaml}" &&
    tar zxvf krew.tar.gz &&
    ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
      --manifest=krew.yaml --archive=krew.tar.gz
  )
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  kubectl krew search
}

_my_k8s_kubectl_upgrade() {
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    [ $(id -u) -eq 0 ] && mv kubectl /usr/local/bin
    [ -n $BASH_VERSINFO ] && hash -r
}

# network monitor
alias dstat='dstat -tc --top-io-adv --top-bio-adv --disk-util --disk-tps --top-cpu-adv'
_my_net_speedtest() {
    echo "[NOTE] monitor network with \`dstat -tdnyc -N eth0 -C total\'"
    echo "[NOTE] monitor network with \`dstat --time --net\'"
    echo "[NOTE] monitor all  with \`dstat --all-plugins\'"
    curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
}

_my_java8_install() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    fi

    case ${OS} in
        *Ubuntu*)
            wget https://d3pxv6yz143wms.cloudfront.net/8.212.04.2/java-1.8.0-amazon-corretto-jdk_8.212.04-2_amd64.deb && \
            apt-get update &&  apt-get install java-common && apt-get install -y --no-install-recommends apt-utils && \
            dpkg --install java-1.8.0-amazon-corretto-jdk_8.212.04-2_amd64.deb
            ;;
        *Linux*)
            yum install https://d3pxv6yz143wms.cloudfront.net/8.222.10.1/java-1.8.0-amazon-corretto-devel-1.8.0_222.b10-1.x86_64.rpm
            ;;
        *)
            echo "This is ${OS} -- Only support installation of java8u212 on Ubuntu"; return 1
            ;;
    esac
}

_my_java_jdb() {
    local PID=$1
    jps -l
    [ -z ${PID} ] && echo "please supply java <pid>"
    jsadebugd ${PID}
    jdb -connect sun.jvm.hotspot.jdi.SADebugServerAttachingConnector:debugServerName=localhost

}
# Maven
_my_maven3_install() {
    wget http://www-eu.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
    sudo tar -xvzf apache-maven-3.2.5-bin.tar.gz -C /opt
    sudo ln -s /opt/{apache-maven-3.2.5,maven}
    cat >> /etc/profile.d/mavenenv.sh <<EOF
export M2_HOME=/opt/maven
export PATH=\${M2_HOME}/bin:\${PATH}

EOF
    sudo chmod +x /etc/profile.d/mavenenv.sh
    source /etc/profile.d/mavenenv.sh
    mvn --version
}

_my_maven_build_faster() {
    local MAVEN_OPTS=${MAVEN_OPTS:-"-XX:+TieredCompilation -XX:TieredStopAtLevel=1"}
    local moduleName=""
    local mavenArgs=""
    if [ ! -n $moduleName ]; then
        mavenArgs="$args -pl ${moduleName}"
    fi
    #mvn -T 1C package -am -—offline $mavenArgs
    mvn -T 1C package -am -DskipTests $mavenArgs
}

_my_flink_dev(){
    [ -d ~/work/src/github.com/apache/flink ] || \
    git clone https://github.com/apache/flink ~/work/src/github.com/apache/flink && \
        cd ~/work/src/github.com/apache/flink && \
        git remote add josh0yeh https://github.com/josh0yeh/flink && \
        git fetch --all
    echo "====> Cloned https://github.come/apache/flink"
    [ -d ~/work/src/github.infra.cloudera.com/CDH/flink ] || \
    git clone https://github.infra.cloudera.com/CDH/flink ~/work/src/github.infra.cloudera.com/CDH/flink || true
    echo "====> Cloned https://github.infra.cloudera.com/CDH/flink"
}

# openssl
_my_openssl_dump_cert_text() {
    local cert=$1
    openssl x509 -in ${cert} -text || \
    openssl x509 -in ${cert} -inform der -text && echo ==== ${cert} is DER format ====
}

_my_openssl_save_cert(){
    local HOST_FQDN=$1
    local PORT=$2
    if [ -z $HOST_FQDN ]; then
        echo "Need to supply HOST in FQDN"  ; return 1
    fi
    echo -n | openssl s_client -connect ${HOST_FQDN}:${PORT}   | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/${HOST_FQDN}.cert
}

_my_maven_bash_completion() {
    local SAVE_AS=~/.bash_completion.maven
    curl -qs https://raw.githubusercontent.com/juven/maven-bash-completion/master/bash_completion.bash > ${SAVE_AS}
    source ${SAVE_AS}
}

_my_maven_run_and_log() {
    # if run
    #   _my_maven_run_and_log mvn clean_package
    # Produce log filename:
    #   9d03fbdf752_flink-tests_mvn_clean_package_1567364394.log
    #   ^^^^^^^^^^^ ^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^
    #   git_hash                mvn_build_command
    #               current_dir                   epoch_time
    local cmd="$@"
    if [ -z "$cmd" ]; then
        cat <<EOF
_my_maven_run_and_log \${maven_commands}
eg:
    $ _my_maven_run_and_log mvn clean package -DskipTests
    $ _my_maven_run_and_log mvn version
EOF
    else
        local logfile="$(git log --pretty=format:'%h' -n 1)_$(basename $(pwd))_${cmd// /_}_$(date +%s).log"

        echo -e ">>>> Executing: ${cmd}"
        echo -e ">>>> Logging:   ${logfile}"
        echo -e ">>>> Log file:  $(realpath ${logfile})"
        time ($cmd) | tee $(git log --pretty=format:'%h' -n 1)_$(basename $(pwd))_${cmd// /_}_$(date +%s).log
    fi
}

# JAVA
alias java_ls='/usr/libexec/java_home -V 2>&1 | cut -s -d , -f 1 | cut -c 5-'
function java_use() {
    export JAVA_HOME=$(/usr/libexec/java_home -v $1)
    java -version
}


# Docker
_my_docker_jmeter() {
    local volume_path=${1:-"workspace/src/github.com/jia3857/jmeter-scripts/jmx"}
    export timestamp=$(date +%Y%m%d_%H%M%S) && \
    export volume_path=${volume_path} && \
    export jmeter_path=/mnt/jmeter && \
    docker run \
      --volume "${volume_path}":${jmeter_path} \
      jmeter \
      -n <any sequence of jmeter args> \
      -t ${jmeter_path}/<jmx_script> \
      -l ${jmeter_path}/tmp/result_${timestamp}.jtl \
      -j ${jmeter_path}/tmp/jmeter_${timestamp}.log
}
# Go
if [ -d $HOME/go ] ; then
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
else
    export PATH=$PATH:$(go env GOPATH)/bin
    export GOPATH=$(go env GOPATH)
    mkdir -p $GOPATH
fi

# bash
relpath(){
    python -c "import os.path; print os.path.relpath('$1','${2:-$PWD}')" ;
}

ln_relpath(){
    #ln -s $(python -c "import os.path; print os.path.relpath('$1','${2:-${1##*/}}')" ;)
    ln -s "$(python -c "import os.path; print os.path.relpath('$1','${2:-$PWD}')")" ;
}
