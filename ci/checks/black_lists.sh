#!/bin/bash
# Copyright (c) 2019, NVIDIA CORPORATION.
##########################################
# cuML black listed function call Tester #
##########################################

TARGET_BRANCH="master"

# Checkout master for comparison
git checkout --quiet $TARGET_BRANCH

# Switch back to tip of PR branch
git checkout --quiet current-pr-branch

# Ignore errors during searching
set +e

# Disable history expansion to enable use of ! in perl regex
set +H

RETVAL=0

for black_listed in cudaDeviceSynchronize cudaMalloc cudaMallocManaged cudaFree cudaMallocHost cudaHostAlloc cudaFreeHost; do
    TMP=`git --no-pager diff --ignore-submodules -w --minimal -U0 -S"$black_listed" $TARGET_BRANCH | grep '^+' | grep -v '^+++' | grep "$black_listed"`
    if [ "$TMP" != "" ]; then
        for filename in `git --no-pager diff --ignore-submodules -w --minimal --name-only -S"$black_listed" $TARGET_BRANCH`; do
            TMP2=`git --no-pager diff --ignore-submodules -w --minimal -U0 -S"$black_listed" $TARGET_BRANCH -- $filename | grep '^+' | grep -v '^+++' | grep "$black_listed"`
            if [ "$TMP2" != "" ]; then
                echo "=== ERROR: black listed function call $black_listed added to $filename ==="
                git --no-pager diff --ignore-submodules -w --minimal -S"$black_listed" $TARGET_BRANCH -- $filename
                echo "=== END ERROR ==="
                RETVAL=1
            fi
        done
    fi
done

for cond_black_listed in cudaMemcpy cudaMemset; do
    TMP=`git --no-pager diff --ignore-submodules -w --minimal -U0 -S"$cond_black_listed" $TARGET_BRANCH | grep '^+' | grep -v '^+++' | grep -P "$cond_black_listed(?!Async)"`
    
    if [ "$TMP" != "" ]; then
        for filename in `git --no-pager diff --ignore-submodules -w --minimal --name-only -S"$cond_black_listed" $TARGET_BRANCH`; do
            TMP2=`git --no-pager diff --ignore-submodules -w --minimal -U0 -S"$cond_black_listed" $TARGET_BRANCH -- $filename | grep '^+' | grep -v '^+++' | grep -P "$cond_black_listed(?!Async)"`
            if [ "$TMP2" != "" ]; then
                echo "=== ERROR: black listed function call $cond_black_listed added to $filename ==="
                git --no-pager diff --ignore-submodules -w --minimal -S"$cond_black_listed" $TARGET_BRANCH -- $filename
                echo "=== END ERROR ==="
                RETVAL=1
            fi
        done
    fi
done

exit $RETVAL
