#!/bin/bash
TESTDIR=$(dirname $(realpath $0))
rm -rf "$TESTDIR/pack"
vim -u "$TESTDIR/vimrc" -c 'JetpackSync' -c 'quitall'
vim -u "$TESTDIR/vimrc" -c "source $TESTDIR/test.vim" -c 'quitall'
