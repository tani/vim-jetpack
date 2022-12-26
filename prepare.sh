rm -rf data
for a in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do

mkdir -p "$PWD/data/$a/lua"
mkdir -p "$PWD/data/$a/plugin"
mkdir -p "$PWD/data/$a/vim/plugin"
CONTENT=`cat <<EOF
local M = {}
function M.setup()
  require('jetpack.util').command[[
    let g:variable_$a = 1
  ]]
end
return M
EOF
`
echo "$CONTENT" > "$PWD/data/$a/lua/$a.lua"
CONTENT=`cat <<EOF
if exists('g:loaded_$a')
  finish
endif
let g:loaded_$a = 1
let g:version_$a = 'v0'
let g:branch_$a = 'main'
map <Plug>$a :
command! Cmd$a :
function! Fun$a()
  let g:installed_$a = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a/plugin/$a.vim"
echo "$CONTENT" > "$PWD/data/$a/vim/plugin/$a.vim"
git init "$PWD/data/$a"
git -C "$PWD/data/$a" add -A
git -C "$PWD/data/$a" commit -m "Initial commit"
git -C "$PWD/data/$a" tag v0
CONTENT=`cat <<EOF
if exists('g:loaded_$a')
  finish
endif
let g:loaded_$a = 1
let g:version_$a = 'v1'
let g:branch_$a = 'main'
map <Plug>$a :
command! Cmd$a :
function! Fun$a()
  let g:installed_$a = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a/plugin/$a.vim"
echo "$CONTENT" > "$PWD/data/$a/vim/plugin/$a.vim"
git -C "$PWD/data/$a" add -A
git -C "$PWD/data/$a" commit -m "Increment version"
git -C "$PWD/data/$a" tag v1
git -C "$PWD/data/$a" branch other
git -C "$PWD/data/$a" switch other
CONTENT=`cat <<EOF
if exists('g:loaded_$a')
  finish
endif
let g:loaded_$a = 1
let g:version_$a = 'v1'
let g:branch_$a = 'other'
map <Plug>$a :
command! Cmd$a :
function! Fun$a()
  let g:installed_$a = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a/plugin/$a.vim"
echo "$CONTENT" > "$PWD/data/$a/vim/plugin/$a.vim"
git -C "$PWD/data/$a" add -A
git -C "$PWD/data/$a" commit -m "Other branch"
git -C "$PWD/data/$a" switch main

done
