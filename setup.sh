#!/bin/bash
set -o pipefail

CURRENT_USER=${USER}
TOOLS="vim tmux iputils-ping net-tools git python3 python3-pip htop"
REPO="https://github.com/vincentto13/LinuxSetup.git"
TMP_REPO_PATH="/tmp/$(basename ${REPO})"

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

spinner() {
    local UNI_DOTS="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    while :; do
        for char in ${UNI_DOTS[@]}; do
            echo -ne "\r${yellow}$char${reset} $1..."
            sleep 0.2
        done
    done
}

caller() {
    local text=$1; shift
    local function=$1; shift

    spinner "${text}" &
    local pid=$!
    ${function} $@ 2>&1 | tee -a ${HOME}/my_env_setup.log > /dev/null
    local result=$?
    kill ${pid}
    if [ ${result} -ne 0 ]; then
        echo -e " ${red}fail${reset}"
        tail -10 ${HOME}/my_env_setup.log
    else
        echo -e " ${green}\xE2\x9C\x94${reset}"
    fi
}

install_docker() {
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --batch --yes --always-trust --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce
    sudo usermod -aG docker ${CURRENT_USER}
}

clone_repo() {
    echo ${TMP_REPO_PATH}
    rm -rf ${TMP_REPO_PATH}
    git clone ${REPO} ${TMP_REPO_PATH}
    return "0"
}

install_keys() {
    mkdir -p ${HOME}/.ssh
    chmod 700 ${HOME}/.ssh
    cat ${TMP_REPO_PATH}/keys/id_rsa.pub > ${HOME}/.ssh/authorized_keys
    chmod 600 ${HOME}/.ssh/authorized_keys
    return "0"
}

install_gitconfig() {
    if [ -f ${TMP_REPO_PATH}/config/.gitconfig ] && [ ! -f ${HOME}/.gitconfig ]; then
        cp ${TMP_REPO_PATH}/config/.gitconfig ${HOME}/.gitconfig
    fi
}

cleanup_repo() {
    rm -rf ${TMP_REPO_PATH}
    return "0"
}

caller "Update package db" sudo apt update 
caller "Upgrade packages" sudo apt upgrade -y
caller "Install tools" sudo apt install ${TOOLS}
caller "Setup python" sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 3

caller "Install docker" install_docker
caller "Clone repository" clone_repo
caller "Install public keys" install_keys
caller "Install .gitconfig" install_gitconfig
caller "Cleanup repository" cleanup_repo