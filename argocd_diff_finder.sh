#!/bin/bash

if [[ -z ${ARGOCD_SERVER} ]]; then
  echo "ARGOCD_SERVER is not set"
  exit 1
fi
if [[ -z "${ARGOCD_USERNAME}" ]]; then
  echo "ARGOCD_USERNAME is not set"
  exit 1
fi

if [[ -z "${ARGOCD_PASSWORD}" ]]; then
  echo "ARGOCD_USERNAME is not set"
  exit 1
fi

if [[ -z "${ARGOCD_GIT_URL}" ]]; then
  echo "ARGOCD_GIT_URL is not set"
  exit 1
fi


## Git find default branch
MAIN_BRANCH_REPO=${MAIN_BRANCH:-"main"}
latestCommitHash=$(git rev-parse HEAD)
ARGOCD_TMP_DIR=${TMP_DIR:-"/tmp/argocd-cd-tmp"}
ACTUALGITREPOURL=$(git config --get remote.origin.url)
PWD=$(pwd)
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-"argocd"}

cecho(){
    RED="\033[0;31m"
    GREEN="\033[1;32m"  
    YELLOW="\033[0;33m"
    CYAN="\033[0;36m"
    BLUE="\033[0;34m"
    PURPLE="\033[0;35m"
    WHITE="\033[0;37m"
    BOLD="\033[1;1m"
    # ... Add more colors if you like

    NC="\033[0m" # No Color

    # printf "${(P)1}${2} ${NC}\n" # <-- zsh
    printf "${!1}${2} ${NC}${3}\n" # <-- bash
}

information () {
    cecho "GREEN" "$1"
}
bold () {
    cecho "BOLD" "$1" 
}

warning () {
    cecho "RED" "$1"
}

loginArgocd() {
    information "Login to ArgoCD ... 🌹"
    argocd logout $ARGOCD_SERVER
    yes | argocd login --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD $ARGOCD_SERVER
}

logoutArgocd() {
    information "Logout from ArgoCD ... 🌹"
    argocd logout $ARGOCD_SERVER
}

argocdGitUrlDiff() {
    if [ "$ACTUALGITREPOURL" != "$ARGOCD_GIT_URL" ]; then
        echo 1
    ## Else
    else
        echo 0
    ## Done
    fi
}

findingAllFilesChangedFromMainBranch() {
    filesChanged=$(git diff --name-only --diff-filter=AM $MAIN_BRANCH_REPO | grep -E "\.ya?ml$")
    if [ -z "$filesChanged" ]; then
        exit 0
    else
        ## Return the files changed
        echo $filesChanged
    fi
}

argocdAppDiff() {
    
    filesYAML=$(find .   -type f -name "*.yaml" -o -type f -name "*.yml")
    ## Echo the length of the filesYAML
    for file in $filesYAML; do
        if grep -q "{{ " $file; then
            continue
        fi
        name=$(yq -e .metadata.name $file  | sed 's/^"//' | sed 's/"$//' | uniq )
        path=$(yq -e .spec.source.path $file 2> /dev/null | sed 's/^"//' | sed 's/"$//' | uniq)
        giturlYaml=$(yq -e .spec.source.repoURL $file 2> /dev/null | sed 's/^"//' | sed 's/"$//' | uniq)
        if [ -n "$name" ] && [ -n "$path" ] && [ "$giturlYaml" == $ACTUALGITREPOURL ]; then
            ## If the path is in filesChanged, then print the name
            if [[ $1 =~ $path ]]; then
                echo "Name: $name"
                echo "Path: $path"
                echo "File Changed: $file"
                echo "---> Running Diff"
                argocd app diff $name --revision $latestCommitHash
                echo "----> Diff Complete"
            fi
        fi
    done
}

cloneArgocdCDRepository() {
    information "Cloning ArgoCD CD Repository ... 🌹"
    ## Clone in temporary directory
    rm -rf  $ARGOCD_TMP_DIR
    git clone $ARGOCD_GIT_URL $ARGOCD_TMP_DIR
    information "Finished cloning ArgoCD CD Repository ... 🌹"
}

argocdDiff() {
    echo "Checking if in ArgoCD Repository"
    repoTrue=$(argocdGitUrlDiff)
    loginArgocd
    if [ $repoTrue -eq 1 ]; then
        warning "Not in ArgoCD Root Repository"
        filesChanged=$(findingAllFilesChangedFromMainBranch)
        if [ -z $filesChanged ]; then
            warning "No files changed"
            return 
        fi
        information "Files Changed: "
        echo $filesChanged
        cloneArgocdCDRepository
        cd $ARGOCD_TMP_DIR
        argocdAppDiff "$filesChanged" 
    else
        echo "In ArgoCD Repository"
        ## Return the files changed
        filesChanged=$(findingAllFilesChangedFromMainBranch)
        if [ -z "$filesChanged" ]; then
            warning "No files changed"
            return
        fi
        information "Files Changed: "
        echo $filesChanged
        argocdAppDiff $filesChanged 

    fi
    logoutArgocd
}

portForwarding() {
    kubectl port-forward svc/argocd-server -n argocd 8080:443  > /dev/null 2>&1 &
    pid=$!
    echo $pid  
}

killPortForwarding() {
    information "Killing Port Forwarding ... 🌹"
    kill $1
    information "Killed Port Forwarding 🌹"
}

information "Main Branch is ${MAIN_BRANCH_REPO}"

## check if first argument is -p or --port-forward
if [ "$1" == "-p" ] || [ "$1" == "--port-forward" ]; then
    pid=$(portForwarding)
    information "Port Forwarding Started 🌹"
    ARGOCD_SERVER="localhost:8080"
    argocdDiff
    killPortForwarding $pid
    information "Port Forwarding Stopped 🌹"
    exit 0
else
    argocdDiff
    exit 0

fi













