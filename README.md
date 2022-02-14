# 🚀 JETPACK.vim

The **lightning-fast** minimalist plugin manager for Vim/ Neovim.

## Benchmark

In the simple cases, JETPACK.vim is the fastest plugin manager.

|  name   | time (ms) |
| :-----: | --------: |
| jetpack |        99 |
|  dein   |       114 |
|  plug   |       129 |

## Installation

Download pack.vim and put it in the `autoload` directory.

### Vim

```
curl -fLo ~/.vim/autoload/pack.vim --create-dirs https://raw.githubusercontent.com/tani/jetpack/master/autoload/pack.vim
```

### Neovim

```
curl -fLo ~/.config/nvim/autoload/pack.vim --create-dirs https://raw.githubusercontent.com/tani/jetpack/master/autoload/pack.vim
```

## Supported options

|   name   |        type        | description                       |
| :------: | :----------------: | :-------------------------------- |
|   `do`   | `string` or `func` | post-update hook                  |
| `branch` |      `sring`       | git branch                        |
|  `rtp`   |      `string`      | path to plugin                    |
|   `as`   |      `string`      | name of plugin                    |
|  `for`   | `string` or `list` | lazy loading for filetypes        |
|   `on`   | `string` or `list` | lazy loading for commands         |
|  `opt`   |     `boolean`      | lazy loading for `packadd {name}` |

## Configuration

- `g:pack#optimization` -- The optimization level for the bundle algorithm.

  | speed | 0 | 1 | 2 |
  | :----:| :-:| :-:| :-:|
  | install | fastest | slow | faster |
  | startup | slow | faster | fastest |
  - `0` -- Bundle nothing. This is the same as vim-plug and is the safest level.
  - `1` -- Bundle if there are no conflicts. It tries to bundle plgins as
    possible. This is default and is safer than `3`.
  - `2` -- Bundle everything. This may be the same as dein.vim, and is the
    fastest level. It overwrites some duplicated files.
    


## Example configuration

### vim-plug style

```vim
call pack#begin()
Pack 'junegunn/fzf.vim'
Pack 'junegunn/fzf', { 'do': {-> fzf#install()} }
Pack 'neoclide/coc.nvim', { 'branch': 'release' }
Pack 'neoclide/coc.nvim', { 'branch': 'master', 'do': '!yarn install --frozen-lockfile' }
Pack 'vlime/vlime', { 'rtp': 'vim' }
Pack 'dracula/vim', { 'as': 'dracula' }
Pack 'tpope/vim-fireplace', { 'for': 'clojure' }
call pack#end()
```

### dein/ minpac style

```vim
call pack#begin()
call pack#add('junegunn/fzf.vim')
call pack#add('junegunn/fzf', { 'do': {-> fzf#install()} })
call pack#add('neoclide/coc.nvim', { 'branch': 'release' })
call pack#add('neoclide/coc.nvim', { 'branch': 'master', 'do': '!yarn install --frozen-lockfile' })
call pack#add('vlime/vlime', { 'rtp': 'vim' })
call pack#add('dracula/vim', { 'as': 'dracula' })
call pack#add('tpope/vim-fireplace', { 'for': 'clojure' })
call pack#end()
```

### packer style

```lua
require('pack').setup(function(use)
  use 'junegunn/fzf.vim'
  use {'junegunn/fzf', do = 'call fzf#install()' }
  use {'neoclide/coc.nvim', branch = 'release'}
  use {'neoclide/coc.nvim', branch = 'master', do = '!yarn install --frozen-lockfile'}
  use {'vlime/vlime', rtp = 'vim' }
  use {'dracula/vim', as = 'dracula' }
  use {'tpope/vim-fireplace', for = 'clojure' }
end)
```

You additionally need to download the lua extension and put it in the `lua`
directory as follows.

```
curl -fLo ~/.config/nvim/lua/pack.lua --create-dirs \
    https://raw.githubusercontent.com/tani/jetpack/master/pack.lua
```

## Q & A

### Why is this plugin so fast?

Because we bundle the all plugins as possible to reduce runtimepath, which takes
a long time at startup. This is the same algorithm of the plugin manager
dein.vim.

### Is this plugin faster than dein?

No if you are vim-wizard. Dein provides many option to tune the startup. Thus,
dein takes milli-seconds to do many things. Our plugin does as the same as
vim-plug, i.e., this plugin provides less options than dein.

## Copyright and License

Copyright (c) 2022 TANIGUCHI Masaya. All rights reserved.

This software is licensed under the MIT License.
