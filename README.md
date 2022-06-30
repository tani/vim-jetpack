# vim-jetpack

The **lightning-fast** minimalist plugin manager for Vim/ Neovim. vim-jetpack is
a jetpack for the most of vimmers. Unbelievably, it is faster than vimrc uses
the built-in plugin manager only.

> **Note**
>
> In new version released in July 2022, we destructively have changed the API.
>
> Please update your `.vimrc`/ `init.vim`.
>
> 1. Add `runtime */jetpack.vim`.
> 2. Rewrite `jetpack#` to `g:jetpack.`.

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

## Installation

Download `jetpack.vim` and put it in the `plugin/` directory.

- Linux / macOS (shell)
  - Vim
    ```
    curl -fLo ~/.vim/plugin/jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
  - Neovim
    ```
    curl -fLo ~/.config/nvim/plugin/jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
- Windows (cmd.exe)
  - Vim
    ```
    curl -fLo %USERPROFILE%\vimfiles\plugin\jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```
  - Neovim
    ```
    curl -fLo %USERPROFILE%\AppData\Local\nvim\plugin\jetpack.vim --create-dirs \
    https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim
    ```

## Usage

### vim-plug style

The most of vim-plug users can migrate to vim-jetpack by `:%s/plug#/jetpack./g`
and `:%s/Plug/Jetpack/g`.

```vim
runtime */jetpack.vim
call g:jetpack.begin()
Jetpack 'https://github.com/dense-analysis/ale'
Jetpack 'junegunn/fzf.vim'
Jetpack 'junegunn/fzf', { 'do': {-> fzf#install()} }
Jetpack 'neoclide/coc.nvim', { 'branch': 'release' }
Jetpack 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' }
Jetpack 'vlime/vlime', { 'rtp': 'vim' }
Jetpack 'dracula/vim', { 'as': 'dracula' }
Jetpack 'tpope/vim-fireplace', { 'for': 'clojure' }
call g:jetpack.end()
```

### dein/ minpac style

```vim
runtime */jetpack.vim
call g:jetpack.begin()
call g:jetpack.add('https://github.com/dense-analysis/ale')
call g:jetpack.add('junegunn/fzf.vim')
call g:jetpack.add('junegunn/fzf', { 'do': {-> fzf#install()} })
call g:jetpack.add('neoclide/coc.nvim', { 'branch': 'release' })
call g:jetpack.add('neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' })
call g:jetpack.add('vlime/vlime', { 'rtp': 'vim' })
call g:jetpack.add('dracula/vim', { 'as': 'dracula' })
call g:jetpack.add('tpope/vim-fireplace', { 'for': 'clojure' })
call g:jetpack.end()
```

### packer style

```lua
vim.cmd('runtime */jetpack.vim')
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

### paq style

```lua
vim.cmd('runtime */jetpack.vim')
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

## API

### Function

- `g:jetpack.begin([path])`
  - The function setups jetpack plugins. All plugin declarations should be
    placed after this function. You can give `path` if you want to use another
    directory to manage plugins.
- `g:jetpack.add(repo [, options])`
  - repo is a pair of string concatenated with `/` such as `tani/vim-jetpack`.
    `options` is a dictionary. See below.
- `g:jetpack.sync()`
  - The function performs to install, update, and bundle all plugins.
    The function is evenrything all you need to know.
    You must run this function after a change of your configuration.
- `g:jetpack.end()`
  - The function loads declared plugins. All plugin declarations should be
    placed before this function.
- `g:jetpack.tap(name)`
  - It returns a truthy value if the plugin is available,
    otherwise it returns a falsy value.
- `g:jetpack.names()`
  - It returns the list of plugin names registered including unavailable
    plugins.
- `g:jetpack.get(name)`
  - It returns metadata of the plugin if possible, otherwise it returns `{}` .
    This is the same as `dein#get` of `dein.vim`.

### Lua Function

All `g:jetpack.` functions are exported as `jetpack` module.
You can call them using `vim.g.jetpack` and `require('jetpack')` as you want.
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
    A command version of `g:jetpack.add()`.
    It is useful for the vim-plug sytle declaration of plugins in vimrc.
- `:JetpackSync`
  - Synchronize configuration and state.
    It performs to install, update, and bundle.
    The shortest abbreviation is `:J`.

### Variable

- `g:jetpack.ignore_patterns`
  - The list of glob-patterns is used to skip duplicated files.
    Jetpack aggressively bundles plugins if you extend this list.
    The following example skip bunding any JSON files.
    ```vim
    call add(g:jetpack.ignore_patterns, '/*.json')
    ```
- `g:jetpack.copy_method`
  - The default value is `'system'`.
    Consider using `'copy'` if you have some trouble to run the
    external commands. `'hardlink'` and `'symlink'` are faster than `'copy'`
    but these are available in Neovim only.
    - `'system'` Use `cp`/ `xcopy` to copy files.
    - `'copy'` Use |readfile| and |writefile| to copy files.
    - `'hardlink'` Use |vim.loop| to make hardlink of files.
    - `'symlink'` Use |vim.loop| to make symlink of files.

- `g:jetpack.download_method`
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

## Q and A

### Why is this plugin so fast?

Because we bundle the all plugins as possible to reduce runtimepath, which takes
a long time at startup. This is the same algorithm of the plugin manager
dein.vim.

### Is this plugin faster than dein?

No if you are vim-wizard. Dein provides many option to tune the startup. Thus,
dein takes milli-seconds to do many things. Our plugin does as the same as
vim-plug, i.e., this plugin provides less options than dein.

### Install vim-jetpack if it is unavailable.

```vim
let s:jetpackfile = expand('<sfile>:p:h') .. '/plugin/jetpack.vim'
let s:jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"
if !filereadable(s:jetpackfile)
  call system(printf('curl -fsSLo %s --create-dirs %s', s:jetpackfile, s:jetpackurl))
endif
```

### How to bootstrap Jetpack

#### Step 1: Clone this repository and create a symbolic link

- Vim
  ```
  git clone https://github.com/tani/vim-jetpack \
  ~/.vim/pack/jetpack/src/vim-jetpack \
  && ln -s ~/.vim/pack/jetpack/{src,opt}/vim-jetpack
  ```
- Neovim
  ```
  git clone https://github.com/tani/vim-jetpack \
  ~/.local/share/nvim/site/pack/jetpack/src/vim-jetpack \
  && ln -s ~/.local/share/nvim/site/pack/jetpack/{src,opt}/vim-jetpack
  ```

#### Step 2: Add `tani/vim-jetpack` to your configuraiton file

- VimL
  ```vim
  packadd vim-jetpack
  call g:jetpack.begin()
  Jetpack 'tani/vim-jetpack', { 'opt': 1 }
  "call g:jetpack.add('tani/vim-jetpack', { 'opt': 1 })
  call g:jetpack.end()
  ```

- Lua
  ```lua
  vim.cmd('packadd vim-jetpack')
  vim.g.jetpack.startup(function (use)
    use { 'tani/vim-jetpack', opt = 1 }
  end)
  -- vim.g.jetpack.setup({
  --   { 'tani/vim-jetpack', opt = 1 }
  -- })
  ```

### Is it possible to install plugins if they are not installed?

Yes, it is. We have `g:jetpack.names()` and `g:jetpack.tap()`
to retrieve a list of plugin names and check the availability.

```vim
for name in g:jetpack.names()
  if !g:jetpack.tap(name)
    call g:jetpack.sync()
    break
  endif
endfor
```

## Copyright and License

Copyright (c) 2022 TANIGUCHI Masaya.

This software is licensed under the MIT License.
