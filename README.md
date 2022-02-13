# 🚀 JETPACK.vim
The lightning-fast plugin manager for Vim/Neovim.

## Installation
Download pack.vim and put it in the "autoload" directory.
```
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/tani/jetpack/master/pack.vim
```

## Example configuration

### vim-plug style

```vim
call pack#begin()
Pack 'junegunn/fzf.vim'
Pack 'junegunn/fzf', { 'do': ':call fzf#install()' }
Pack 'neoclide/coc.nvim', {'branch': 'release'}
Pack 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
Pack 'vlime/vlime', { 'rtp': 'vim' }
Pack 'dracula/vim', { 'as': 'dracula' }
Pack 'tpope/vim-fireplace', { 'for': 'clojure' }
call pack#end()
```

### dein/ minpac style

```vim
pack#add('junegunn/fzf.vim')
pack#add('junegunn/fzf', { 'do': ':call fzf#install()' })
pack#add('neoclide/coc.nvim', {'branch': 'release'})
pack#add('neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'})
pack#add('vlime/vlime', { 'rtp': 'vim' })
pack#add('dracula/vim', { 'as': 'dracula' })
pack#add('tpope/vim-fireplace', { 'for': 'clojure' })
```

## Copyright and License

Copyright (c) 2022 TANIGUCHI Masaya. All rights reserved.

This software is licensed under the MIT License.
