# 🚀 vim-jetpack

The **lightning-fast** minimalist plugin manager for Vim/ Neovim. vim-jetpack is
a jetpack for the most of vimmers. Unbelievably, it is faster than vimrc uses
the built-in plugin manager only.

![jetpack](https://user-images.githubusercontent.com/5019902/154419764-d246c45c-8940-4e60-9658-9ed3424cbeaa.gif)

## Features

- Lightning-fast startup
    - It optimizes the search algorithm for the runtimepath
- Single file plugin
    - You need to just put the single file to use this software
- Multiple DSLs (Domain Specific Languages)
    - You can use a favorite notations, which are similar to vim-plug, dein.vim, packer.nvim, and paq.nvim
- Fancy UI (User Interface)
    - You can see a progress of installation with a graphical interface
- `pack/*/start`-free architecture.
    - Installed plugins do not pollutes your vim until calling `jetpack#`-functions

## Benchmark

In the simple cases, vim-jetpack is the fastest plugin manager.

We measured a startup time 10 times for each plugin managers. The following chart is the result.

![jetpack_benchmark](https://user-images.githubusercontent.com/5019902/154288762-ff9def96-3f8e-428c-bcb5-d16b3712e9fe.png)

|          |  dein | jetpack | minpac | packer |   paq |  plug |
| :------: | ----: | ------: | -----: | -----: | ----: | ----: |
| min      | 80.61 |   69.93 |  64.97 |  75.38 | 73.92 | 77.63 |
| max      | 96.02 |   74.48 |  81.30 |  89.40 | 84.95 | 82.82 |
| median   | 85.26 |   71.92 |  72.38 |  78.38 | 78.16 | 80.36 |
| mean     | 86.24 |   71.97 |  72.48 |  80.07 | 78.21 | 80.12 |
| variance | 27.09 |    2.07 |  23.99 |  24.56 | 10.83 |  3.57 |

You can run the benchmarks in your local environment. See the `benchmark`
directory for more detail. 

## Installation

Download jetpack.vim and put it in the `autoload` directory.

### Vim

```
curl -fLo ~/.vim/autoload/jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
```

### Neovim

```
curl -fLo ~/.config/nvim/autoload/jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
```

If you want to install lua interface, instead of the above, you can install jetpack.vim together with jetpack.lua as follows.

```
git clone --depth 1 https://github.com/tani/vim-jetpack ~/.local/share/nvim/site/pack/jetpack/start/vim-jetpack
```

## Supported options

vim-jetpack is 90% compatible with vim-plug.

|      name       |        type        | description                           |
| :-------------: | :----------------: | :------------------------------------ |
| `branch`/ `tag` |      `sring`       | Branch/ tag of the repository to use  |
|      `rtp`      |      `string`      | Subdirectory that contains Vim plugin |
|      `dir`      |      `string`      | Custom directory for the plugin       |
|      `as`       |      `string`      | Use different name for plugin         |
|      `do`       | `string` or `func` | Post-updat hook                       |
|      `on`       | `string` or `list` | On-demand loading: Commands, `<Plug>` |
|      `for`      | `string` or `list` | On-demand loading: File types         |
|      `opt`      |     `boolean`      | On-demand loading: `packadd {name}`   |
|    `frozen`     |     `boolean`      | Do not update                         |

We welcome a pull request to add the `on` option for non-normal mode and the
`commit` option.

## Configuration

- `g:jetpack#optimization` -- The optimization level for the bundle algorithm.

  |  speed  |    0    |   1    |    2    |
  | :-----: | :-----: | :----: | :-----: |
  | install | fastest |  slow  | faster  |
  | startup |  slow   | faster | fastest |
  - `0` -- Bundle nothing. This is the same as vim-plug and is the safest level.
  - `1` -- Bundle if there are no conflicts. It tries to bundle plgins as
    possible. This is default and is safer than `3`.
  - `2` -- Bundle everything. This may be the same as dein.vim, and is the
    fastest level. It overwrites some duplicated files.

## Commands

- `:JetpackSync` -- Synchronize configuration and state. It performs to install,
  update, and bundle.

## Example Usage

### vim-plug style

The most of vim-plug users can migrate to vim-jetpack by `:%s/plug/jetpack/g` and
`:%s/Plug/Jetpack/g`.

```vim
call jetpack#begin()
Jetpack 'junegunn/fzf.vim'
Jetpack 'junegunn/fzf', { 'do': {-> fzf#install()} }
Jetpack 'neoclide/coc.nvim', { 'branch': 'release' }
Jetpack 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' }
Jetpack 'vlime/vlime', { 'rtp': 'vim' }
Jetpack 'dracula/vim', { 'as': 'dracula' }
Jetpack 'tpope/vim-fireplace', { 'for': 'clojure' }
call jetpack#end()
```

### dein/ minpac style

```vim
call jetpack#begin()
call jetpack#add('junegunn/fzf.vim')
call jetpack#add('junegunn/fzf', { 'do': {-> fzf#install()} })
call jetpack#add('neoclide/coc.nvim', { 'branch': 'release' })
call jetpack#add('neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' })
call jetpack#add('vlime/vlime', { 'rtp': 'vim' })
call jetpack#add('dracula/vim', { 'as': 'dracula' })
call jetpack#add('tpope/vim-fireplace', { 'for': 'clojure' })
call jetpack#end()
```

### Lua extension

You additionally need to download the lua extension and put it in the `lua`
directory as follows.

```
curl -fLo ~/.config/nvim/lua/jetpack.lua --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/lua/jetpack.lua
```

#### packer style

```lua
require('jetpack').startup(function(use)
  use 'junegunn/fzf.vim'
  use {'junegunn/fzf', do = 'call fzf#install()' }
  use {'neoclide/coc.nvim', branch = 'release'}
  use {'neoclide/coc.nvim', branch = 'master', do = 'yarn install --frozen-lockfile'}
  use {'vlime/vlime', rtp = 'vim' }
  use {'dracula/vim', as = 'dracula' }
  use {'tpope/vim-fireplace', for = 'clojure' }
end)
```

#### paq style

```lua
require('jetpack').setup {
  'junegunn/fzf.vim',
  {'junegunn/fzf', do = 'call fzf#install()' },
  {'neoclide/coc.nvim', branch = 'release'},
  {'neoclide/coc.nvim', branch = 'master', do = 'yarn install --frozen-lockfile'},
  {'vlime/vlime', rtp = 'vim' },
  {'dracula/vim', as = 'dracula' },
  {'tpope/vim-fireplace', for = 'clojure' },
}
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
