rm -rf data

for a in A; do
for b in {1..32}; do

mkdir -p "$PWD/data/$a$b/lua"
mkdir -p "$PWD/data/$a$b/plugin"
mkdir -p "$PWD/data/$a$b/vim/plugin"
CONTENT=`cat <<EOF
local M = {}
function M.setup()
  require('jetpack.util').command[[
    let g:variable_$a$b = 1
  ]]
end
return M
EOF
`
echo "$CONTENT" > "$PWD/data/$a$b/lua/$a$b.lua"
CONTENT=`cat <<EOF
if exists('g:loaded_$a$b')
  finish
endif
let g:loaded_$a$b = 1
let g:version_$a$b = 'v0'
let g:branch_$a$b = 'main'
map <Plug>$a$b :
command! Cmd$a$b :
function! Fun$a$b()
  let g:installed_$a$b = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a$b/plugin/$a$b.vim"
echo "$CONTENT" > "$PWD/data/$a$b/vim/plugin/$a$b.vim"
git init "$PWD/data/$a$b"
git -C "$PWD/data/$a$b" add -A
git -C "$PWD/data/$a$b" commit -m "Initial commit"
git -C "$PWD/data/$a$b" tag v0
CONTENT=`cat <<EOF
if exists('g:loaded_$a$b')
  finish
endif
let g:loaded_$a$b = 1
let g:version_$a$b = 'v1'
let g:branch_$a$b = 'main'
map <Plug>$a$b :
command! Cmd$a$b :
function! Fun$a$b()
  let g:installed_$a$b = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a$b/plugin/$a$b.vim"
echo "$CONTENT" > "$PWD/data/$a$b/vim/plugin/$a$b.vim"
git -C "$PWD/data/$a$b" add -A
git -C "$PWD/data/$a$b" commit -m "Increment version"
git -C "$PWD/data/$a$b" tag v1
git -C "$PWD/data/$a$b" branch other
git -C "$PWD/data/$a$b" switch other
CONTENT=`cat <<EOF
if exists('g:loaded_$a$b')
  finish
endif
let g:loaded_$a$b = 1
let g:version_$a$b = 'v1'
let g:branch_$a$b = 'other'
map <Plug>$a$b :
command! Cmd$a$b :
function! Fun$a$b()
  let g:installed_$a$b = 1
endfunction
EOF
`
echo "$CONTENT" > "$PWD/data/$a$b/plugin/$a$b.vim"
echo "$CONTENT" > "$PWD/data/$a$b/vim/plugin/$a$b.vim"
git -C "$PWD/data/$a$b" add -A
git -C "$PWD/data/$a$b" commit -m "Other branch"
git -C "$PWD/data/$a$b" switch main

done
done

rm $PWD/.git/config
