#!/bin/bash
#
# Because the llvm-mirror/clang repo has no stand alone repo for python
# bindings, we have created https://github.com/trolldbois/python-clang .
# we can them push that package to Pypi https://pypi.python.org/pypi/clang .
# This repository really contains python setup.py and some fixes in 
# alternate branches
#
# alternatively, because I'm patching llvm-mirror/clang, 
# I have forked to https://github.com/trolldbois/clang to include patches
# So the origin repo for clang, for my purpose is mine on github.
# The clang local repo is in a subfolder of llvm/tools/
#
# There are additional update scripts in my llvm local repo to update these.
# 
# For my local clang repo
# master should always be a mirror of upstream master.
# any dev should be done in a branch ("visit-fields", "etcc")
#
# For my local python-clang repo
# master should always be a mirror of upstream master clang/bindings/python.
# any dev should be done in a branch ("visit-fields", "etcc")
# Why a different repo ? only to package in Pypi.
#
#
# The idea of this update.sh script is 
# Step a) Merge llvm from the master upstream repo. (pulling, no conflicts expected)
# Step b) Merge clang master branch from master upstream repo. We do not expect 
#    origin (mine) to have anything interesting new in my github master.
#   Otherwise it should be done in a branch.
#
# Step c) python-clang update our local repo master branch 
#  with llvm-mirror/clang/bindings/python master files
#
# Step d) suggest to merge master with whatever local branch you are working on
#
#

# Tune this
LLVM_LOCAL_REPO=~/compil/llvm
PYTHON_CLANG_LOCAL_REPO=~/compil/python-clang

if [ ! -v LLVM_LOCAL_REPO -o ! -v PYTHON_CLANG_LOCAL_REPO ]; then
    echo "Please fix this script."
    exit 1
fi

# we do not intend to clone, push nor pull from that local repo 
SHALLOW_GIT="--depth=10"


LLVM_GIT_REPOSITORY_URL=https://github.com/llvm-mirror/llvm.git
CLANG_UPSTREAM_GIT_REPOSITORY_URL=https://github.com/llvm-mirror/clang.git
CLANG_ORIGIN_GIT_REPOSITORY_URL=git@github.com:trolldbois/clang.git
CLANG_LOCAL_REPO=$LLVM_LOCAL_REPO/tools/clang


CURCWD=`pwd`

# get llvm if required
if [ ! -d "$LLVM_LOCAL_REPO" ]; then
    echo "#############################################"
    echo "Cloning LLVM repo from $LLVM_GIT_REPOSITORY_URL"
    mkdir -p $LLVM_LOCAL_REPO
    echo git clone --recursive -b master --single-branch $SHALLOW_GIT $LLVM_GIT_REPOSITORY_URL $LLVM_LOCAL_REPO
    git clone --recursive -b master --single-branch $SHALLOW_GIT $LLVM_GIT_REPOSITORY_URL $LLVM_LOCAL_REPO
    if [ $? -ne 0 ]; then
        echo "Error while clone-ing llvm master - Aborting"
        exit 1
    fi
    echo "#############################################"
else
    # otherwise sync it
    echo "#############################################"
    echo "updating llvm local repository"
    cd $LLVM_LOCAL_REPO
    git checkout master
    if [ $? -ne 0 ]; then
        echo "Error while checking out llvm master - Aborting"
        exit 1
    fi
    echo "git pull $LLVM_GIT_REPOSITORY_URL master"
    git pull $LLVM_GIT_REPOSITORY_URL master
    if [ $? -ne 0 ]; then
        echo "Error while pull-ing llvm master - Aborting"
        exit 1
    fi
    echo "#############################################"
fi

cd $CURCWD

# get clang in llvm tools folder if required
if [ ! -d "$CLANG_LOCAL_REPO" ]; then
    echo "#############################################"
    echo "Cloning CLANG repo from $CLANG_ORIGIN_GIT_REPOSITORY_URL"
    mkdir -p $CLANG_LOCAL_REPO
    echo git clone --recursive -b master $CLANG_ORIGIN_GIT_REPOSITORY_URL $CLANG_LOCAL_REPO
    git clone --recursive -b master $CLANG_ORIGIN_GIT_REPOSITORY_URL $CLANG_LOCAL_REPO
    cd $CLANG_LOCAL_REPO
    echo git remote add upstream $CLANG_UPSTREAM_GIT_REPOSITORY_URL
    git remote add upstream $CLANG_UPSTREAM_GIT_REPOSITORY_URL
    if [ $? -ne 0 ]; then
        echo "Error while clone-ing clang master - Aborting"
        exit 1
    fi
    echo "#############################################"
fi

# in all cases
echo "#############################################"
echo "updating clang local repository with upstream news"
cd $CLANG_LOCAL_REPO
git checkout master
if [ $? -ne 0 ]; then
    echo "Error while checking out clang master - Aborting"
    exit 1
fi
echo "#############################################"
echo "git pull upstream master"
git pull upstream master
if [ $? -ne 0 ]; then
    echo "Error while pulling upstream clang master - Aborting"
    exit 1
fi
# update my github
echo "git push origin"
git push origin
if [ $? -ne 0 ]; then
    echo "Error while pulling upstream clang master - Aborting"
    exit 1
fi
#git merge upstream/master
echo "#############################################"

# prepping the commit log for python-clang
cd $CLANG_LOCAL_REPO
COMMIT=`git rev-parse HEAD`

cd $PYTHON_CLANG_LOCAL_REPO
git checkout master
if [ $? -ne 0 ]; then
    echo "** Error while switching to python-clang master branch - Aborting"
    exit 1
fi

echo "Removing old files..."
rm -rf $PYTHON_CLANG_LOCAL_REPO/clang
rm -rf $PYTHON_CLANG_LOCAL_REPO/examples
rm -rf $PYTHON_CLANG_LOCAL_REPO/tests

echo ""
echo "Copying new files"
cp -a $CLANG_LOCAL_REPO/bindings/python/clang $PYTHON_CLANG_LOCAL_REPO/
cp -a $CLANG_LOCAL_REPO/bindings/python/examples $PYTHON_CLANG_LOCAL_REPO/
cp -a $CLANG_LOCAL_REPO/bindings/python/tests $PYTHON_CLANG_LOCAL_REPO/

git add clang examples tests -v
echo "TODO:"
echo "    " git commit -m "updated from https://github.com/llvm-mirror/clang.git - Last commit llvm-mirror/clang/commit/$COMMIT"
echo "    # change to your dev branches"
echo "    git merge master"
echo "#############################################"
# git push
