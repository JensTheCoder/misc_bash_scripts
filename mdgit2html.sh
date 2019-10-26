#!/bin/bash
# mdgit2html.sh
# Markdown to html with pandoc. Manage your private knowledge base with git.
# Call this script through crontab and index the html target with recoll.
# Author: Jens Bormueller
# https://github.com/JensTheCoder/misc_bash_scripts.git
# Example: mdgit2html.sh ssh://domain.com/var/local/git/md-docs.git /md-docs /md-html
# Dependencies
# apt-get install pandoc
# apt-get install recoll

GITREPO="$1"
GITPATH="${2%/}"
TARGETPATH="${3%/}"
INIT=0

CURDIR=$(pwd)

if [ ! -d "$GITPATH" ]; then
        INIT=1
fi

mkdir -p "$GITPATH"
cd "$GITPATH"

if [ $INIT -eq 1 ]; then
        git init 
        git remote add origin "$GITREPO"
        git fetch
        git checkout origin/master -f
fi

if [ $INIT -eq 0 ]; then
        git fetch
        UPDATEDLIST=$(git diff --name-only origin/master)
        git reset --hard origin/master
fi

# build entire target on init
if [ $INIT -eq 1 ]; then

        # copy directories without files
        rsync -a --exclude '.*/' --include '*/' --exclude '*' "./" "$TARGETPATH/"

        find . -name '*.md' -exec sh -c 'TAGETPATH="$0" ; SOURCEFILE="$1" ; pandoc "$SOURCEFILE" -s --toc -o "$TAGETPATH/${SOURCEFILE%.md}.html"' "$TARGETPATH" "{}" \;      
fi

# remove all files and directories from target
# that got updated or removed by git from source dir
if [ $INIT -eq 0 ]; then
        for SOURCEFILE in $UPDATEDLIST; do
                if [ ! -e $SOURCEFILE ]; then

                        # files
                        TARGETFILE="${SOURCEFILE%.md}.html"
                        if [ -f "$TARGETPATH/$TARGETFILE" ]; then
                                rm "$TARGETPATH/$TARGETFILE" 
                        fi
                fi
        done

        # rsync can't remove non empty directories,
        # so we call it after removing all files above
        rsync -a --exclude '.*/' --include '*/' --exclude '*' --delete "./" "$TARGETPATH/" 
fi


# update or create target
if [ $INIT -eq 0 ]; then

        # copy directories without files
        rsync -a --exclude '.*/' --include '*/' --exclude '*' "./" "$TARGETPATH/"

        for SOURCEFILE in $UPDATEDLIST; do
                if [ -f $SOURCEFILE -a ${SOURCEFILE##*.} == "md" ]; then
                        pandoc "$SOURCEFILE" -s --toc -o "$TARGETPATH/${SOURCEFILE%.md}.html"
                fi
        done
fi

cd "$CURDIR"

