#!/bin/bash

printf "\nNvimLink"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call NvimLink()' -c 'q'

printf "\nNvimSymLink"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call NvimSymlink()' -c 'q'

printf "\nCopy"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call Copy()' -c 'q'

printf "\nSystemCopy"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call SystemCopy()' -c 'q'

printf "\nSystemLink"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call SystemLink()' -c 'q'

printf "\nSystemSymlink"
rm -rf output* && time nvim -u NONE --headless -c "source $(pwd)/benchmark.vim" -c 'call SystemSymlink()' -c 'q'

rm -rf output*
