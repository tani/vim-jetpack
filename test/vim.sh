#!/bin/bash
TESTDIR=$(dirname $(realpath $0))
rm -rf "$TESTDIR/pack"
vim -s "$TESTDIR/null.vim" -u "$TESTDIR/vimrc" -c 'JetpackSync' -c 'quitall'
vim -u "$TESTDIR/vimrc" -s "$TESTDIR/test.vim" -c 'quitall'
