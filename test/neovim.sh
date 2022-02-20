#!/bin/bash
TESTDIR=$(dirname $(realpath $0))
rm -rf "$TESTDIR/pack"
nvim -u $TESTDIR/vimrc -c 'JetpackSync' -c 'quitall'
nvim -u $TESTDIR/vimrc -c "source $TESTDIR/test.vim" -c 'quitall'
