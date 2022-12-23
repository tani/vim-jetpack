set packpath=
call execute(printf('source %s/plugin/jetpack.vim', expand('<sfile>:p:h:h')))

function s:fallback(val, default)
  return empty(a:val) ? a:default : a:val
endfunction

let g:jetpack_copy_method = s:fallback(getenv('JETPACK_COPY_METHOD'), 'system')
let g:jetpack_download_method = s:fallback(getenv('JETPACK_DOWNLOAD_METHOD'), 'git')

let s:suite = themis#suite('Jetpack Tests')
let s:assert = themis#helper('assert')
let g:vimhome = substitute(expand('<sfile>:p:h'), '\', '/', 'g')
let s:optdir =  g:vimhome . '/pack/jetpack/opt'
let s:srcdir =  g:vimhome . '/pack/jetpack/src'

call delete(g:vimhome . '/pack', 'rf')

function s:setup(...)
  call jetpack#begin(g:vimhome)
  for plugin in a:000
    if len(plugin) == 2
      call jetpack#add(plugin[0], plugin[1])
    else
      call jetpack#add(plugin[0])
    endif
  endfor
  call jetpack#end()
  call jetpack#sync()
  call feedkeys("\<CR>", 'n')
endfunction

function s:assert.filereadable(file)
  if !filereadable(a:file)
    call s:assert.fail(a:file . ' is not readable')
  endif
endfunction

function s:assert.notfilereadable(file)
  if filereadable(a:file)
    call s:assert.fail(a:file . ' is readable')
  endif
endfunction

function s:assert.isdirectory(dir)
  if !isdirectory(a:dir)
    call s:assert.fail(a:dir . ' is not a directory')
  endif
endfunction

function s:assert.isnotdirectory(dir)
  if isdirectory(a:dir)
    call s:assert.fail(a:dir . ' is a directory')
  endif
endfunction

function s:assert.loaded(package)
  try
    let loaded = luaeval('package.loaded[_A]', a:package)
    call s:assert.not_equals(loaded, v:null, a:package . ' is not loaded')
  catch /.*/
    " Cannot convert given lua type. So, not v:null (it's loaded).
  endtry
endfunction

function s:assert.notloaded(package)
  try
    let loaded = luaeval('package.loaded[_A]', a:package)
    call s:assert.equals(loaded, v:null, a:package . ' is loaded')
  catch /.*/
    " Cannot convert given lua type. So, not v:null (it's loaded).
    call s:assert.fail(a:package . ' is loaded')
  endtry
endfunction

function s:suite.parse_toml()
let toml =<<EOF
[[plugins]]
repo = 'tani/jetpack.vim'
opt = true
depends = [
  'Shougo/deoplete.nvim',
  'Shougo/vimproc.vim',
]
hook_add = '''
  let g:jetpack_loaded = 1
'''
[[plugins]]
repo = 'tani/glance-vim'
opt = 1
hook_add = '''let g:glance_loaded = 1'''
[[plugins]]
repo = 'tani/ddc-fuzzy'
hook_add = '''
let g:ddc_fuzzy_loaded = 1'''
EOF
let plugins = jetpack#parse_toml(toml)
call s:assert.equals(plugins[0].repo, 'tani/jetpack.vim')
call s:assert.equals(plugins[0].opt, 1)
call s:assert.equals(plugins[0].depends[0], 'Shougo/deoplete.nvim')
call s:assert.equals(plugins[0].depends[1], 'Shougo/vimproc.vim')
call s:assert.match(plugins[0].hook_add, 'let g:jetpack_loaded = 1')
call s:assert.equals(plugins[1].repo, 'tani/glance-vim')
call s:assert.equals(plugins[1].opt, 1)
call s:assert.match(plugins[1].hook_add, 'let g:glance_loaded = 1')
call s:assert.equals(plugins[2].repo, 'tani/ddc-fuzzy')
call s:assert.match(plugins[2].hook_add, 'let g:ddc_fuzzy_loaded = 1')
endfunction

function s:suite.multiple_plugins_with_the_same_ondemand_command()
  call s:setup(
  \ ['tpope/vim-commentary', { 'on': 'Test' }],
  \ ['tpope/vim-surround', { 'on': 'Test' }]
  \ )
  call s:assert.isdirectory(s:optdir . '/vim-commentary')
  call s:assert.isdirectory(s:optdir . '/vim-surround')
  call s:assert.not_exists('g:loaded_commentary')
  call s:assert.not_exists('g:loaded_surround')
  silent! Test
  call s:assert.exists('g:loaded_commentary')
  call s:assert.exists('g:loaded_surround')
endfunction

function s:suite.no_option_github()
  call s:setup(['mbbill/undotree'])
  call s:assert.isnotdirectory(s:optdir . '/undotree')
  call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.no_option_url()
  call s:setup(['https://github.com/mbbill/undotree'])
  call s:assert.isnotdirectory(s:optdir . '/undotree')
  call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.opt_option()
  call s:setup(['junegunn/goyo.vim', { 'opt': 1 }])
  let s:loaded_goyo_vim = 0
  augroup JetpackTest
    au!
    autocmd User JetpackGoyoVimPost let s:loaded_goyo_vim = 1
  augroup END
  call s:assert.isdirectory(s:optdir . '/goyo.vim')
  call s:assert.filereadable(s:optdir . '/goyo.vim/plugin/goyo.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/goyo.vim')
  call s:assert.cmd_not_exists('Goyo')
  call s:assert.false(s:loaded_goyo_vim)
  call jetpack#load('goyo.vim')
  call s:assert.cmd_exists('Goyo')
  call s:assert.true(s:loaded_goyo_vim)
endfunction

function s:suite.do_func_option()
  let bin = 'fzf' . (has('win32') ? '.exe' : '')
  call s:setup(['junegunn/fzf', { 'do': { -> fzf#install() } }])
  call s:assert.isdirectory(s:optdir . '/fzf')
  call s:assert.filereadable(s:optdir . '/fzf/bin/' . bin)
endfunction

function s:suite.do_str_option()
  let cmd = './install'
  if has('win32')
    let cmd = 'powershell -ExecutionPolicy Bypass -file ' . cmd . '.ps1'
  endif
  let bin = 'fzf' . (has('win32') ? '.exe' : '')
  call s:setup(['junegunn/fzf', { 'do': cmd }])
  call s:assert.isdirectory(s:optdir . '/fzf')
  call s:assert.filereadable(s:optdir . '/fzf/bin/' . bin)
endfunction

function s:suite.for_option()
  call s:setup(['junegunn/vader.vim', { 'for': 'vader' }])
  let s:loaded_vader_vim = 0
  augroup JetpackTest
    au!
    autocmd User JetpackVaderVimPost let s:loaded_vader_vim = 1
  augroup END
  call s:assert.isdirectory(s:optdir . '/vader.vim')
  call s:assert.filereadable(s:optdir . '/vader.vim/plugin/vader.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/vader.vim')
  call s:assert.cmd_not_exists('Vader')
  call s:assert.false(s:loaded_vader_vim)
  let filetype = &filetype
  setf vader
  call s:assert.cmd_exists('Vader')
  call s:assert.true(s:loaded_vader_vim)
  let &filetype = filetype
endfunction

function s:suite.on_option_cmd()
  call s:setup(['tpope/vim-abolish', { 'on': 'Abolish' }])
  let s:loaded_abolish_vim = 0
  augroup JetpackTest
    autocmd!
    autocmd User JetpackVimAbolishPost let s:loaded_abolish_vim = 1
  augroup END
  call s:assert.isdirectory(s:optdir . '/vim-abolish')
  call s:assert.filereadable(s:optdir . '/vim-abolish/plugin/abolish.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/abolish.vim')
  call s:assert.cmd_exists('Abolish')
  call s:assert.cmd_not_exists('Subvert')
  call s:assert.false(s:loaded_abolish_vim)
  silent! Abolish
  call s:assert.cmd_exists('Abolish')
  call s:assert.cmd_exists('Subvert')
  call s:assert.true(s:loaded_abolish_vim)
endfunction

function s:suite.on_option_plug()
  call s:setup(['vim-skk/eskk.vim', { 'on': '<Plug>(eskk' }])
  call s:assert.notfilereadable(s:optdir . '/_/plugin/eskk.vim')
  call s:assert.isdirectory(s:optdir . '/eskk.vim')
  call s:assert.filereadable(s:optdir . '/eskk.vim/plugin/eskk.vim')
  let s:loaded_eskk_vim = 0
  augroup JetpackTest
    autocmd!
    autocmd User JetpackEskkVimPost let s:loaded_eskk_vim = 1
  augroup END
  call s:assert.cmd_not_exists('EskkMap')
  call s:assert.false(s:loaded_eskk_vim)
  call feedkeys('', 'x')
  call feedkeys("i\<Plug>(eskk:toggle)\<Esc>", 'x')
  call feedkeys('', 'x')
  call s:assert.cmd_exists('EskkMap')
  call s:assert.true(s:loaded_eskk_vim)
endfunction

function s:suite.on_source()
  call s:setup(
  \ ['ctrlpvim/ctrlp.vim', { 'opt': 1 }],
  \ ['tracyone/ctrlp-findfile', { 'on_source': 'ctrlp.vim' }]
  \ )
  call s:assert.isdirectory(s:optdir . '/ctrlp.vim')
  call s:assert.isdirectory(s:optdir . '/ctrlp-findfile')
  call s:assert.cmd_not_exists('CtrlP')
  call s:assert.cmd_not_exists('CtrlPFindFile')
  call jetpack#load('ctrlp.vim')
  call s:assert.cmd_exists('CtrlP')
  call s:assert.cmd_exists('CtrlPFindFile')
endfunction

function s:suite.on_option_event()
  call s:setup(['tpope/vim-fugitive', { 'on': 'User Test' }])
  let s:loaded_fugitive = 0
  augroup JetpackTest
    autocmd!
    autocmd User JetpackVimFugitivePost let s:loaded_fugitive = 1
  augroup END
  call s:assert.notfilereadable(s:optdir . '/_/plugin/fugitive.vim')
  call s:assert.isdirectory(s:optdir .  '/vim-fugitive')
  call s:assert.filereadable(s:optdir .  '/vim-fugitive/plugin/fugitive.vim')
  call s:assert.cmd_not_exists('Git')
  call s:assert.false(s:loaded_fugitive)
  doautocmd User Test
  call s:assert.true(s:loaded_fugitive)
  call s:assert.cmd_exists('Git')
endfunction

function s:suite.rtp_option()
  call s:setup(['vlime/vlime', { 'rtp': 'vim' }])
  call s:assert.isnotdirectory(s:optdir . '/vlime')
  call s:assert.isnotdirectory(s:optdir . '/_/vim')
  call s:assert.filereadable(s:optdir . '/_/syntax/vlime_repl.vim')
endfunction

function s:suite.issue15()
  call s:setup(['vim-test/vim-test'])
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.names()
  call s:setup(['vim-test/vim-test'])
  call s:assert.equals(jetpack#names(), ['vim-test'])
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.tap()
  call s:setup(['vim-test/vim-test'])
  call s:assert.true(jetpack#tap('vim-test'))
  call s:assert.false(jetpack#tap('_____'))
endfunction

function s:suite.get()
  call s:setup(['vim-test/vim-test'])
  let data = jetpack#get('vim-test')
  call s:assert.equals(data.url, 'https://github.com/vim-test/vim-test')
  call s:assert.equals(data.opt, 0)
  call s:assert.equals(substitute(data.path, '\', '/', 'g'), s:srcdir .. '/github.com/vim-test/vim-test')
endfunction

function s:suite.change_repo_url()
  call s:setup(['sveltejs/template'])
  call s:setup(['readthedocs/template'])
  call s:assert.match(jetpack#get('template').path, 'readthedocs')
endfunction

function s:suite.frozen_option()
  call s:assert.skip('')
endfunction

function s:suite.tag_option()
  call s:setup(['uga-rosa/ccc.nvim', { 'tag': 'v1.0.0' }])
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let indent = matchstr(readfile(s:optdir . '/_/stylua.toml')[3], '\d\+')
  call s:assert.equals(indent, '4')
endfunction

function s:suite.branch_option()
  call s:setup(['uga-rosa/ccc.nvim', { 'branch': '0.7.2' }])
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let first_line_readme = readfile(s:optdir . '/_/README.md', '', 1)[0]
  call s:assert.compare(first_line_readme, '=~#', 'Since 0.8.0 has been released')
endfunction

function s:suite.commit_option()
  call s:setup(['uga-rosa/ccc.nvim', { 'commit': 'db80a70' }])
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let indent = matchstr(readfile(s:optdir . '/_/stylua.toml')[3], '\d\+')
  call s:assert.equals(indent, '2')
endfunction

function s:suite.issue70()
  call s:setup(['s1n7ax/nvim-window-picker'], ['p00f/nvim-ts-rainbow'])
  call s:assert.filereadable(s:optdir . '/_/screenshots')
  call s:assert.isdirectory(s:optdir. '/nvim-ts-rainbow/screenshots')
endfunction

function s:suite.local_plugin()
  let install_path = expand(g:vimhome . '/pack/linkformat.vim')
  call system('git clone --depth 1 https://github.com/uga-rosa/linkformat.vim ' . install_path)
  call s:setup([install_path])
  call s:assert.equals(jetpack#get('linkformat.vim').path, install_path)
  call s:assert.match(&rtp, '\V'.escape(install_path, '\'))
endfunction

function s:suite.self_delete()
  let src_path = expand(s:srcdir . '/github.com/tani/vim-jetpack')
  let opt_path = expand(s:optdir . '/vim-jetpack')
  
  " When jetpack is added, it does not delete itself.
  call s:setup(['tani/vim-jetpack', { 'opt': 1 }])
  call s:assert.isdirectory(src_path)
  call s:assert.isdirectory(opt_path)
  
  " When jetpack is not added, it ask me to delete itself.
  call jetpack#begin(g:vimhome)
  call jetpack#end()
  
  " If you press "no", nothing will happen.
  augroup SelfDeletePressKey
    au!
    au CmdlineEnter * call feedkeys("no\<CR>", "n")
  augroup END
  call jetpack#sync()
  call s:assert.isdirectory(opt_path)
  
  " If you press "yes", it will delete the directory
  augroup SelfDeletePressKey
    au!
    autocmd CmdlineEnter * call feedkeys("yes\<CR>", "n")
  augroup END
  call jetpack#sync()
  call s:assert.isnotdirectory(opt_path)
  
  " If you have an old jetpack, don't ask.
  call s:setup(['tani/vim-jetpack', { 'opt': 1 }])
  call system('git -C ' . src_path . ' fetch --depth 2')
  call system('git -C ' . src_path . ' reset --hard HEAD~')
  call jetpack#sync()
  call s:assert.isdirectory(src_path)
  call s:assert.isdirectory(opt_path)
endfunction

if !has('nvim') && !(has('lua') && has('patch-8.2.0775'))
  finish 
endif

lua <<EOL
local packer = require('jetpack.packer')

packer.init({
  package_root = require('jetpack.util').eval('g:vimhome') .. '/pack',
})

_G.packer_setup = function(...)
local plugins = { ... }
packer.startup(function(use)
  for _, plugin in ipairs(plugins) do
    use(plugin)
  end
end)
require('jetpack').sync()
end
EOL

function s:suite.packer_style_complex()
  let g:nightfox_setup_done = 0
  let g:nightfox_config_done = 0
  call s:assert.equals(g:nightfox_setup_done, 0)
  call s:assert.equals(g:nightfox_config_done, 0)
lua<<EOF
  packer_setup({
    'EdenEast/nightfox.nvim',
    setup = function()
      require('jetpack.util').command('let g:nightfox_setup_done = 1')
    end,
    config = function()
      require('jetpack.util').command('let g:nightfox_config_done = 1')
    end
  })
EOF
  call jetpack#load('nightfox.nvim')
  call s:assert.isnotdirectory(s:optdir . '/nightfox.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/nightfox.vim')
  call s:assert.equals(g:nightfox_setup_done, 1)
  call s:assert.equals(g:nightfox_config_done, 1)
endfunction

if !has('nvim')
  finish
endif

function s:suite.pkg_config()
lua <<EOL
  packer_setup({
    'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').set_icon({
        zsh = {
          icon = '',
        },
      })
    end,
  })
EOL
  call s:assert.isnotdirectory(s:optdir . '/nvim-web-devicons')
  call s:assert.filereadable(s:optdir . '/_/plugin/nvim-web-devicons.vim')
  call s:assert.notloaded('nvim-web-devicons')
  call s:assert.true(jetpack#load('nvim-web-devicons'), 'nvim-web-devicons cannot be loaded')
  call s:assert.loaded('nvim-web-devicons') " means config is called
  let zsh_icon = luaeval('require("nvim-web-devicons").get_icon("foo.zsh")')
  call s:assert.equals(zsh_icon, '', 'zsh_icon is expected ``, but got ' . zsh_icon)
endfunction

function s:suite.only_lua()
lua <<EOL
  packer_setup({
  'nathom/filetype.nvim',
  config = function()
    require("filetype").setup({
      overrides = {
        extensions = {
          -- Set the filetype of *.pn files to potion
          pn = "potion",
        },
      }
    })
  end
  })
EOL
  call s:assert.isnotdirectory(s:optdir . '/filetype.nvim')
  call s:assert.isdirectory(s:optdir . '/_/lua/filetype')
  call s:assert.notloaded('filetype')
  call s:assert.true(jetpack#load('filetype.nvim'), 'filetype.nvim cannot be loaded')
  call s:assert.loaded('filetype') " means config is called
  edit foo.pn
  lua require('filetype').resolve()
  call s:assert.equals(&ft, 'potion', '&ft is expected `potion`, but got ' . &ft)
endfunction

function! s:suite.pkg_requires() abort
lua <<EOL
  packer_setup({
    'hrsh7th/nvim-cmp',
    opt = true,
  }, {
    'hrsh7th/cmp-buffer',
    requires = 'nvim-cmp',
    opt = true,
  })
EOL
  call s:assert.isdirectory(s:optdir . '/nvim-cmp')
  call s:assert.isdirectory(s:optdir . '/cmp-buffer')
  call s:assert.isnotdirectory(s:optdir . '/_/lua/cmp')
  call s:assert.isnotdirectory(s:optdir . '/_/lua/cmp_buffer')
  call s:assert.true(jetpack#load('cmp-buffer'), 'cmp-buffer cannot be loaded')
  call s:assert.true(jetpack#tap('nvim-cmp'), 'nvim-cmp is not loaded') " means nvim-cmp is also loaded
  call s:assert.loaded('cmp_buffer') " means cmp-buffer/after/plugin is sourced
endfunction

