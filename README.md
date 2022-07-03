# vim-jetpack

The **lightning-fast** minimalist plugin manager for Vim/ Neovim. vim-jetpack is
a jetpack for the most of vimmers. Unbelievably, it is faster than vimrc uses
the built-in plugin manager only.

<img src="https://user-images.githubusercontent.com/5019902/154419764-d246c45c-8940-4e60-9658-9ed3424cbeaa.gif" width="70%">

## Features

- Lightning-fast startup
  - It optimizes the search algorithm for the runtimepath.
- Single file plugin
  - You need to just put the single file to use this software.
- First-class Lua support
  - This plugin is not written in Lua but we provide a lua interface.
- Fancy UI (User Interface)
  - You can see a progress of installation with a graphical interface.
- `pack/*/start`-free architecture
  - Installed plugins do not pollute your vim.
- git-free installation
  - Optionally, you can use `curl`/ `wget` instead of `git`

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

<img src="https://user-images.githubusercontent.com/5019902/154288762-ff9def96-3f8e-428c-bcb5-d16b3712e9fe.png" width="70%">


|          |  dein | jetpack | minpac | packer |   paq |  plug |
| :------: | ----: | ------: | -----: | -----: | ----: | ----: |
|   min    | 80.61 |   69.93 |  64.97 |  75.38 | 73.92 | 77.63 |
|   max    | 96.02 |   74.48 |  81.30 |  89.40 | 84.95 | 82.82 |
|  median  | 85.26 |   71.92 |  72.38 |  78.38 | 78.16 | 80.36 |
|   mean   | 86.24 |   71.97 |  72.48 |  80.07 | 78.21 | 80.12 |
| variance | 27.09 |    2.07 |  23.99 |  24.56 | 10.83 |  3.57 |

You can run the benchmarks in your local environment. See the `benchmark`
directory for more detail

## Installation

Download `jetpack.vim` and put it in the `plugin/` directory.

- Linux / macOS (shell)
  - Vim
    ```
    curl -fLo ~/.vim/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
  - Neovim
    ```
    curl -fLo ~/.local/share/nvim/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
- Windows (cmd.exe)
  - Vim
    ```
    curl -fLo %USERPROFILE%\vimfiles\pack\jetpack\opt\vim-jetpack\plugin\jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
  - Neovim
    ```
    curl -fLo %USERPROFILE%\AppData\Local\nvim-data\site\pack\jetpack\opt\vim-jetpack\plugin\jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```

## Usage

### vim-plug style

The most of vim-plug users can migrate to vim-jetpack by `:%s/plug#/jetpack#/g`
and `:%s/Plug/Jetpack/g`.

```vim
packadd vim-jetpack
call jetpack#begin()
Jetpack 'tani/vim-jetpack', {'opt': 1} "bootstrap
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
packadd vim-jetpack
call jetpack#begin()
call jetpack#add('tani/vim-jetpack', {'opt': 1}) "bootstrap
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

### packer style

```lua
vim.cmd('packadd vim-jetpack')
require('jetpack').startup(function(use)
  use { 'tani/vim-jetpack', opt = 1 }-- bootstrap
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

### paq style

```lua
vim.cmd('packadd vim-jetpack')
require('jetpack').setup {
  {'tani/vim-jetpack', opt = 1}, -- bootstrap
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

## API

### Function

- `jetpack#begin([path])`
  - The function setups jetpack plugins. All plugin declarations should be
    placed after this function. You can give `path` if you want to use another
    directory to manage plugins.
- `jetpack#add(repo [, options])`
  - repo is a pair of string concatenated with `/` such as `tani/vim-jetpack`.
    `options` is a dictionary. See below.
- `jetpack#sync()`
  - The function performs to install, update, and bundle all plugins.
    The function is evenrything all you need to know.
    You must run this function after a change of your configuration.
- `jetpack#end()`
  - The function loads declared plugins. All plugin declarations should be
    placed before this function.
- `jetpack#tap(name)`
  - It returns a truthy value if the plugin is available,
    otherwise it returns a falsy value.
- `jetpack#names()`
  - It returns the list of plugin names registered including unavailable
    plugins.
- `jetpack#get(name)`
  - It returns metadata of the plugin if possible, otherwise it returns `{}` .
    This is the same as `dein#get` of `dein.vim`.

### Lua Function

All `jetpack#` functions are exported as `jetpack` module.
You can call them using `require('jetpack')` as you want.
Additionaly, `startup` and `setup` functions are available.

- `setup(config)`
  - This function loads plugins described in config like `pack.nvim`.
- `startup(config)`
  - This function loads plugins described by `use` function like `packer.nvim`.

### Supported Option

vim-jetpack contains all optoins of vim-plug.

| name         | type               | description                           |
| :----------: | :----------------: | :------------------------------------ |
| `commit`     | `sring`            | Commit of the repository to use       |
| `tag`        | `sring`            | Tag of the repository to use          |
| `branch`     | `sring`            | Branch of the repository to use       |
| `rtp`        | `string`           | Subdirectory that contains Vim plugin |
| `dir`        | `string`           | Custom directory for the plugin       |
| `as`         | `string`           | Use different name for plugin         |
| `do` / `run` | `string` or `func` | Post-update hook                      |
| `on`         | `string` or `list` | Commands, keymaps, events, file types |
| `for` / `ft` | `string` or `list` | On-demand loading: File types         |
| `cmd`        | `string` or `list` | On-demand loading: Commands           |
| `event`      | `string` or `list` | On-demand loading: Events             |
| `map`        | `string` or `list` | On-demand loading: keymaps `<Plug>`   |
| `opt`        | `boolean`          | On-demand loading: `packadd {name}`   |
| `frozen`     | `boolean`          | Do not update                         |

### Command

- `:Jetpack repo [, options]`
    A command version of `jetpack#add()`.
    It is useful for the vim-plug sytle declaration of plugins in vimrc.
- `:JetpackSync`
  - Synchronize configuration and state.
    It performs to install, update, and bundle.
    The shortest abbreviation is `:J`.

### Variable

- `g:jetpack_ignore_patterns`
  - The list of glob-patterns is used to skip duplicated files.
    Jetpack aggressively bundles plugins if you extend this list.
    The following example skip bunding any JSON files.
    ```vim
    call add(g:jetpack_ignore_patterns, '/*.json')
    ```
- `g:jetpack_copy_method`
  - The default value is `'system'`.
    Consider using `'copy'` if you have some trouble to run the
    external commands. `'hardlink'` and `'symlink'` are faster than `'copy'`
    but these are available in Neovim only.
    - `'system'` Use `cp`/ `xcopy` to copy files.
    - `'copy'` Use |readfile| and |writefile| to copy files.
    - `'hardlink'` Use |vim.loop| to make hardlink of files.
    - `'symlink'` Use |vim.loop| to make symlink of files.

- `g:jetpack_download_method`
  - The default value is `'git'`. 
    Consider using `'curl'` or `'wget'`
    if `'git'` is not installed in your system.
    - `'git'` Use `'git'` to download plugins.
    - `'curl'` Use `'curl'` to download plugins.
    - `'wget'` Use `'wget'` to download plugins.

### Event

- `User Jetpack{PluginName}Pre`/ `User Jetpack{PluginName}Post`
  - Let {PluginName} be a CamelCase of plugin name.
    Code to execute when the plugin is lazily loaded on demand with
    `User Jetpack{PluginName}Post` .
    It is impossible to hook `packadd` for a lua plugin in Neovim,
    because Neovim does not load any files until the module is required.
    
    | plugin-name  | EventName  |
    | :----------: | :--------: |
    | vim-jetpack  | VimJetpack |
    | goyo.vim     | GoyoVim    |
    | vim_foo      | VimFoo     |

### Autocmd Group

- `Jetpack`
  - vim-jetpack's lazy loading system uses autocommands defined
    under the `Jetpack` autocmd-groups.

## Tips

### Install vim-jetpack if it is unavailable.

```vim
let s:jetpackfile = expand('<sfile>:p:h') .. 'pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim'
let s:jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"
if !filereadable(s:jetpackfile)
  call system(printf('curl -fsSLo %s --create-dirs %s', s:jetpackfile, s:jetpackurl))
endif
```

### Is it possible to install plugins if they are not installed?

Yes, it is. We have `jetpack#names()` and `jetpack#tap()`
to retrieve a list of plugin names and check the availability.

```vim
for name in jetpack#names()
  if !jetpack#tap(name)
    call jetpack#sync()
    break
  endif
endfor
```

## Copyright and License

Copyright (c) 2022 TANIGUCHI Masaya.

This software is licensed under the MIT License.
