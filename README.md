<p align="center"><img src="https://argo-cd.readthedocs.io/en/stable/assets/logo.png" width="180px" /></p>


# Argocd Diff Finder

**Argocd Diff Finder** is a small bash script that can tell you what your actual changes on your resources will be when you merge your changes to the ArgoCD repository.

## Why you need it

- It's **free**, easy and open source. 
- It's easy to install
- No more pain knowing what your changes will be when you merge your changes to the ArgoCD repository.

## Features

- It's a bash script :D (no need to install anything)
- None except telling you the differences between your changes and the state of your app in Kubernetes.

## Demo

Display the demo.gif from folder demo

<p align="center"><img src="../argocd-diff-finder/demo/demo.gif" width="800px" /></p>

## How it works

Argocd Diff Finder works with two configurations:
- All your app declarations and their helm charts, yaml files are in the same repository (ARGOCD_GIT_URL)
- You have a repository for your app declarations and point to another repository for your helm charts and yaml files.
  - In this case, Argocd diff finder needs to be run on the repository that host your helm charts and yaml files.
  - It will clone the argocd repository and then run the diff finder on the cloned repository.
    - It will extract information in your app configurations in order to find the name of your argo apps that have been impacted by the changes
- It uses the `argocd app diff` command to find the differences between your changes and the state of your app in Kubernetes. 

## Usage

- Optional: Install dyff
  - `brew install homeport/tap/dyff`
  - `export KUBECTL_EXTERNAL_DIFF="dyff between -b "`
- Go to your branch with the changes you want to merge.
- Make sure you pushed your changes
- Make a port forward to your argocd server if it is not publicly accessible
- Export the following variables
```bash
export ARGOCD_SERVER=<localhost:8080> # The ArgoCD server address
export ARGOCD_USERNAME=<username> # The ArgoCD username
export ARGOCD_PASSWORD=<password> # The ArgoCD password
export ARGOCD_GIT_URL=<git-url> # The ArgoCD git url with you applications configuration
```
- Optional: change some values
```bash
export MAIN_BRANCH=<main-branch> # The main branch of your application - default main
export ARGOCD_TMP_DIR=<tmp-dir> # The temporary directory to store the diffs - default /tmp/argocd-cd-tmp
```

- Run the script on your branch with the changes
```bash
bash argocd_diff_finder.sh #./argocd_diff_finder.sh
```

## Contributions

Please feel free to add any contribution.
I might, if I have the time, translate it into go.

## Disclaimers

It comes as is, without any warranty.