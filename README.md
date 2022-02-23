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
  - You can use a favorite notations, which are similar to vim-plug, dein.vim,
    packer.nvim, and paq.nvim
- Fancy UI (User Interface)
  - You can see a progress of installation with a graphical interface
- `pack/*/start`-free architecture.
  - Installed plugins do not pollutes your vim until calling
    `jetpack#`-functions

## Benchmark

In the simple cases, vim-jetpack is the fastest plugin manager.

We measured a startup time 10 times for each plugin managers. The following
chart is the result.

Although jetpack is inferior to minpac in terms of minimum value, it has the
lowest median and mean value of any plugin manager. More notably, the variance
of jetpack's records is very small. vim-plug's variance is small enough, but
jetpack's variance is by far the smallest. jetpack has the smallest variance,
mean, and median among the six plugin managers, indicating that it is stable and
always runs fast.

![jetpack_benchmark](https://user-images.githubusercontent.com/5019902/154288762-ff9def96-3f8e-428c-bcb5-d16b3712e9fe.png)

|          |  dein | jetpack | minpac | packer |   paq |  plug |
| :------: | ----: | ------: | -----: | -----: | ----: | ----: |
|   min    | 80.61 |   69.93 |  64.97 |  75.38 | 73.92 | 77.63 |
|   max    | 96.02 |   74.48 |  81.30 |  89.40 | 84.95 | 82.82 |
|  median  | 85.26 |   71.92 |  72.38 |  78.38 | 78.16 | 80.36 |
|   mean   | 86.24 |   71.97 |  72.48 |  80.07 | 78.21 | 80.12 |
| variance | 27.09 |    2.07 |  23.99 |  24.56 | 10.83 |  3.57 |

You can run the benchmarks in your local environment. See the `benchmark`
directory for more detail.

## Installation

Download jetpack.vim and put it in the `autoload` directory.

### Linux / macOS

- Vim
  ```
  curl -fLo ~/.vim/autoload/jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
  ```
- Neovim
  ```
  curl -fLo ~/.config/nvim/autoload/jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
  ```

### Windows

- Vim
  ```
  curl -fLo ~\vimfiles\autoload\jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
  ```
- Neovim
  ```
  curl -fLo ~\AppData\Local\nvim\autoload\jetpack.vim --create-dirs https://raw.githubusercontent.com/tani/vim-jetpack/master/autoload/jetpack.vim
  ```

## Supported options

vim-jetpack is almost compatible with vim-plug.

|           name            |        type        | description                                  |
| :-----------------------: | :----------------: | :------------------------------------------- |
| `branch`/ `tag`/ `commit` |      `sring`       | Branch/ tag/ commit of the repository to use |
|           `rtp`           |      `string`      | Subdirectory that contains Vim plugin        |
|           `dir`           |      `string`      | Custom directory for the plugin              |
|           `as`            |      `string`      | Use different name for plugin                |
|           `do`            | `string` or `func` | Post-update hook                             |
|           `on`            | `string` or `list` | On-demand loading: Commands, `<Plug>`        |
|           `for`           | `string` or `list` | On-demand loading: File types                |
|         `frozen`          |     `boolean`      | Do not update                                |

Note that `on` option is only for the normal/ visual/ insert mode.
Additionally, Jetpack provides Vim 8/ Neovim style on-demand loading interface.

|           name            |        type        | description                                  |
| :-----------------------: | :----------------: | :------------------------------------------- |
|           `opt`           |     `boolean`      | On-demand loading: `packadd {name}`          |

## Configuration

- `g:jetpack#optimization` -- The optimization level for the bundle algorithm.

  |  speed  |    0    |   1    |    2    |
  | :-----: | :-----: | :----: | :-----: |
  | install | fastest |  slow  | faster  |
  | startup |  slow   | faster | fastest |
  - `0` -- Bundle nothing. This is the same as vim-plug and is the safest level.
  - `1` -- Bundle if there are no conflicts. It tries to bundle plgins as
    possible. This is default and is safer than `2`.
  - `2` -- Bundle everything. This may be the same as dein.vim, and is the
    fastest level. It overwrites some duplicated files.

## Commands

- `:JetpackSync` -- Synchronize configuration and state. It performs to install,
  update, and bundle.

## Example Usage

### vim-plug style

The most of vim-plug users can migrate to vim-jetpack by `:%s/plug/jetpack/g`
and `:%s/Plug/Jetpack/g`.

```vim
call jetpack#begin()
Jetpack 'https://github.com/dense-analysis/ale'
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
call jetpack#add('https://github.com/dense-analysis/ale')
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

You can use aliases `run` and `ft` insetead of `do` and `for` because of the
reserved keywords in lua.

#### packer style

```lua
require('jetpack').startup(function(use)
  use 'https://github.com/dense-analysis/ale'
  use 'junegunn/fzf.vim'
  use {'junegunn/fzf', run = 'call fzf#install()' }
  use {'neoclide/coc.nvim', branch = 'release'}
  use {'neoclide/coc.nvim', branch = 'master', run = 'yarn install --frozen-lockfile'}
  use {'vlime/vlime', rtp = 'vim' }
  use {'dracula/vim', as = 'dracula' }
  use {'tpope/vim-fireplace', ft = 'clojure' }
end)
```

#### paq style

```lua
require('jetpack').setup {
  'https://github.com/dense-analysis/ale',
  'junegunn/fzf.vim',
  {'junegunn/fzf', run = 'call fzf#install()' },
  {'neoclide/coc.nvim', branch = 'release'},
  {'neoclide/coc.nvim', branch = 'master', run = 'yarn install --frozen-lockfile'},
  {'vlime/vlime', rtp = 'vim' },
  {'dracula/vim', as = 'dracula' },
  {'tpope/vim-fireplace', ft = 'clojure' },
}
```

## Supported Platforms

We continuously test this software on the nightly version of Vim/ Neovim for
Ubuntu, macOS, Windows. The current status is
[![linux](https://github.com/tani/vim-jetpack/actions/workflows/linux.yml/badge.svg)](https://github.com/tani/vim-jetpack/actions/workflows/linux.yml)
[![macos](https://github.com/tani/vim-jetpack/actions/workflows/macos.yml/badge.svg)](https://github.com/tani/vim-jetpack/actions/workflows/macos.yml)
[![windows](https://github.com/tani/vim-jetpack/actions/workflows/windows.yml/badge.svg)](https://github.com/tani/vim-jetpack/actions/workflows/windows.yml)
.
## Q & A

### Why is this plugin so fast?

Because we bundle the all plugins as possible to reduce runtimepath, which takes
a long time at startup. This is the same algorithm of the plugin manager
dein.vim.

### Is this plugin faster than dein?

No if you are vim-wizard. Dein provides many option to tune the startup. Thus,
dein takes milli-seconds to do many things. Our plugin does as the same as
vim-plug, i.e., this plugin provides less options than dein.

### How to bootstrap Jetpack

#### Step 1: Clone this repository and create a symbolic link

- Vim
  ```
  git clone --depth 1 https://github.com/tani/vim-jetpack ~/.vim/pack/jetpack/src/vim-jetpack && ln -s ~/.vim/pack/jetpack/{src,opt}/vim-jetpack
  ```
- Neovim
  ```
  git clone --depth 1 https://github.com/tani/vim-jetpack ~/.local/share/nvim/site/pack/jetpack/src/vim-jetpack && ln -s ~/.local/share/nvim/site/pack/jetpack/{src,opt}/vim-jetpack
  ```

#### Step 2: Add `tani/vim-jetpack` to your configuraiton file

- Vimscirpt
  ```vim
  packadd vim-jetpack
  call jetpack#begin()
  Jetpack 'tani/vim-jetpack', { 'opt': 1 }
  call jetpack#add('tani/vim-jetpack', { 'opt': 1 })
  call jetpack#end()
  ```
- Lua
  ```lua
  vim.cmd('packadd vim-jetpack')

  require'jetpack'.startup(function ()
    use { 'tani/vim-jetpack', opt = 1 }
  end)

  require'jetpack'.setup {
    { 'tani/vim-jetpack', opt = 1 }
  }
  ```

### Is it possible to isntall plugins if they are not installed?

If we expose the variable `g:plugs` like vim-plug, it will be difficult to
change the internal data structure of the plugin in the future, which may affect
the performance improvement in the future. Therefore, jetpack does not expose
such variables, but exposes the function `jetpack#tap()` instead. This function
checks whether a given plugin is installed or not.

```vim
let plugs = [
\   'some/plugins'
\ ]
jetpack#begin()
for plug in plugs
  call jetpack#add(plug)
endfor
jetpack#end()

"Run jetpack#sync if some plugins is not installed
for plug in plugs
  if jetpack#tap(fnamemodify(plug, ':t'))
    call jetpack#sync()
    break
  endif
endfor
```

## Copyright and License

Copyright (c) 2022 TANIGUCHI Masaya. All rights reserved.

This software is licensed under the MIT License.
