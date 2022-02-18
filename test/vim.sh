#!/bin/bash
TESTDIR=$(dirname $(realpath $0))
rm -rf "$TESTDIR/pack"
vim -s /dev/null -u "$TESTDIR/vimrc" -c 'JetpackSync' -c 'quitall'
vim -u "$TESTDIR/vimrc" -s "$TESTDIR/test.vim" -c 'quitall'
