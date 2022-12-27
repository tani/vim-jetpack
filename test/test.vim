set packpath=
"set verbose=1
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

function Git(dir, commands)
  for cmd in a:commands
    call system('git -C '.a:dir.' '.cmd)
  endfor
endfunction

function Setup(...)
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

function DummyPath(name)
  return fnamemodify(g:vimhome, ':p:h:h').'/data/'.a:name
endfunction

function DummyUrl(name)
  return 'file://'.fnamemodify(g:vimhome, ':p:h:h').'/data/'.a:name
endfunction

let s:counter = 0
function UniqueId()
  let s:counter += 1
  return 'X'.s:counter
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
  let g:id1 = UniqueId()
  let g:id2 = UniqueId()
  call mkdir(DummyPath(g:id1).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id1.' = 1'],
  \ DummyPath(g:id1).'/plugin/'.g:id1.'.vim'
  \ )
  call Git(DummyPath(g:id1), ['init', 'add -A', 'commit -m "Initial commit"'])
  call mkdir(DummyPath(g:id2).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id2.' = 1'],
  \ DummyPath(g:id2).'/plugin/'.g:id2.'.vim'
  \ )
  call Git(DummyPath(g:id2), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup(
  \ [DummyUrl(g:id1), { 'on_cmd': 'Test' }],
  \ [DummyUrl(g:id2), { 'on_cmd': 'Test' }]
  \ )
  call s:assert.isdirectory(s:optdir.'/'.g:id1)
  call s:assert.isdirectory(s:optdir.'/'.g:id2)
  call s:assert.not_exists('g:loaded_'.g:id1)
  call s:assert.not_exists('g:loaded_'.g:id2)
  silent Test
  call s:assert.exists('g:loaded_'.g:id1)
  call s:assert.exists('g:loaded_'.g:id2)
endfunction

function s:suite.no_option_github()
  call jetpack#begin(g:vimhome)
  call jetpack#add('foo/bar')
  call jetpack#end()
  call s:assert.equals(jetpack#get('bar').url, 'https://github.com/foo/bar')
endfunction

function s:suite.no_option_url()
  call jetpack#begin(g:vimhome)
  call jetpack#add('https://github.com/mbbill/undotree')
  call jetpack#end()
  call s:assert.equals(jetpack#get('undotree').url, 'https://github.com/mbbill/undotree')
endfunction

function s:suite.opt()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'opt': 1 }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.not_exists('g:loaded_'.g:id)
  call jetpack#load(g:id)
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.do_func()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ [
  \ 'let g:loaded_'.g:id.' = 1',
  \ 'function Install'.g:id.'()',
  \ 'let g:installed_'.g:id.'=1',
  \ 'endfunction'
  \ ],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim')
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'do': { -> execute('call Install'.g:id.'()') } }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.exists('g:loaded_'.g:id)
  call s:assert.exists('g:installed_'.g:id)
endfunction

function s:suite.on_ft()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(['let g:loaded_'.g:id.' = 1'], DummyPath(g:id).'/plugin/'.g:id.'.vim')
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'on_ft': 'c' }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.not_exists('g:loaded_'.g:id)
  let filetype = &filetype
  setf c
  call s:assert.exists('g:loaded_'.g:id)
  let &filetype = filetype
endfunction

function s:suite.on_cmd()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile([
  \ 'let g:loaded_'.g:id.' = 1',
  \ 'command Load'.g:id.' :'
  \ ],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim')
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'on_cmd': 'Load'.g:id }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.not_exists('g:loaded_'.g:id)
  silent! execute 'Load'.g:id
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.on_map()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile([
  \ 'let g:loaded_'.g:id.' = 1',
  \ 'map <Plug>'.g:id.' :'
  \],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim')
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'on_map': '<Plug>'.g:id }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.not_exists('g:loaded_'.g:id)
  call feedkeys('', 'x')
  call feedkeys("\<Plug>".g:id, 'x')
  call feedkeys('', 'x')
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.on_source()
  let g:id1 = UniqueId()
  let g:id2 = UniqueId()
  call mkdir(DummyPath(g:id1).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id1.' = 1'],
  \ DummyPath(g:id1).'/plugin/'.g:id1.'.vim'
  \ )
  call Git(DummyPath(g:id1), ['init', 'add -A', 'commit -m "Initial commit"'])
  call mkdir(DummyPath(g:id2).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id2.' = 1'],
  \ DummyPath(g:id2).'/plugin/'.g:id2.'.vim'
  \ )
  call Git(DummyPath(g:id2), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup(
  \ [DummyUrl(g:id1), { 'opt': 1 }],
  \ [DummyUrl(g:id2), { 'on_source': g:id1 }]
  \ )
  call s:assert.isdirectory(s:optdir.'/'.g:id1)
  call s:assert.isdirectory(s:optdir.'/'.g:id2)
  call s:assert.not_exists('g:loaded_'.g:id1)
  call s:assert.not_exists('g:loaded_'.g:id2)
  call jetpack#load(g:id1)
  call s:assert.exists('g:loaded_'.g:id1)
  call s:assert.exists('g:loaded_'.g:id2)
endfunction

function s:suite.on_post_source()
  let g:id1 = UniqueId()
  let g:id2 = UniqueId()
  call mkdir(DummyPath(g:id1).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id1.' = 1'],
  \ DummyPath(g:id1).'/plugin/'.g:id1.'.vim'
  \ )
  call Git(DummyPath(g:id1), ['init', 'add -A', 'commit -m "Initial commit"'])
  call mkdir(DummyPath(g:id2).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id2.' = 1'],
  \ DummyPath(g:id2).'/plugin/'.g:id2.'.vim'
  \ )
  call Git(DummyPath(g:id2), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup(
  \ [DummyUrl(g:id1), { 'opt': 1 }],
  \ [DummyUrl(g:id2), { 'on_post_source': g:id1 }]
  \ )
  call s:assert.isdirectory(s:optdir.'/'.g:id1)
  call s:assert.isdirectory(s:optdir.'/'.g:id2)
  call s:assert.not_exists('g:loaded_'.g:id1)
  call s:assert.not_exists('g:loaded_'.g:id2)
  call jetpack#load(g:id1)
  call s:assert.exists('g:loaded_'.g:id1)
  call s:assert.exists('g:loaded_'.g:id2)
endfunction

function s:suite.on_event()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'on_event': 'User '.g:id }])
  call s:assert.isdirectory(s:optdir.'/'.g:id)
  call s:assert.not_exists('g:loaded_'.g:id)
  execute 'doautocmd User' g:id
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.rtp()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/vim/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/vim/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id), { 'rtp': 'vim' }])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.issue15()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/autoload/test', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/autoload/test/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyPath(g:id)])
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.names()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id)])
  call s:assert.equals(jetpack#names(), [g:id])
endfunction

function s:suite.tap()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id)])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  call s:assert.true(jetpack#tap(g:id), g:id.' is not installed')
  call s:assert.false(jetpack#tap('_'), '_ is installed')
endfunction

function s:suite.get()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id)])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  let data = jetpack#get(g:id)
  call s:assert.equals(type(data), type({}))
  call s:assert.false(empty(data), 'data is empty')
endfunction

function s:suite.frozen_option()
  call s:assert.skip('')
endfunction

function s:suite.tag_option()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"', 'tag v1'])
  call writefile(
  \ ['let g:loaded_'.g:id.' = 2'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['add -A', 'commit -m "Second commit"', 'tag v2'])
  call Setup([DummyUrl(g:id), {'tag': 'v1'}])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  call s:assert.equals(g:loaded_{g:id}, 1)
endfunction

function s:suite.branch_option()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"', 'branch other', 'switch other'])
  call writefile(
  \ ['let g:loaded_'.g:id.' = 2'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['add -A', 'commit -m "Second commit"', 'switch main'])
  call Setup([DummyUrl(g:id), { 'branch': 'other' }])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  call s:assert.equals(g:loaded_{g:id}, 2)
endfunction

function s:suite.commit_option()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call writefile(
  \ ['let g:loaded_'.g:id.' = 2'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['add -A', 'commit -m "Second commit"'])
  let g:ids = systemlist('git -C '.DummyPath(g:id).' log -3 --pretty=format:"%h"')
  call Setup([DummyUrl(g:id), { 'commit': g:ids[1] }])
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
  call s:assert.equals(g:loaded_{g:id}, 1)
endfunction

function s:suite.issue70()
  call mkdir(DummyPath(g:id1).'/screenshots', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id1.' = 1'],
  \ DummyPath(g:id1).'/screenshots/'.g:id1.'.vim'
  \ )
  call Git(DummyPath(g:id1), ['init', 'add -A', 'commit -m "Initial commit"'])
  call mkdir(DummyPath(g:id2), 'p')
  call writefile(
  \ ['let g:loaded_'.g:id2.' = 1'],
  \ DummyPath(g:id2).'/screenshots'
  \ )
  call Git(DummyPath(g:id2), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyUrl(g:id1)], [DummyUrl(g:id2)])
  call s:assert.isdirectory(s:optdir . '/_/screenshots')
  call s:assert.filereadable(s:optdir. '/'.g:id2.'/screenshots')
endfunction

function s:suite.local_plugin()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
  call Setup([DummyPath(g:id)])
  call s:assert.isdirectory(DummyPath(g:id))
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function s:suite.self_delete()
  let src_path = expand(s:srcdir . '/github.com/tani/vim-jetpack')
  let opt_path = expand(s:optdir . '/vim-jetpack')
  
  " When jetpack is added, it does not delete itself.
  call Setup(['tani/vim-jetpack', { 'opt': 1 }])
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
  call Setup(['tani/vim-jetpack', { 'opt': 1 }])
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

function s:suite.packer_style()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
lua<<EOF
  packer_setup({
    vim.fn.DummyUrl(vim.g.id),
  })
EOF
  call s:assert.filereadable(s:optdir . '/_/plugin/'.g:id.'.vim')
endfunction

function s:suite.packer_style_setup()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id.' = 1'],
  \ DummyPath(g:id).'/plugin/'.g:id.'.vim'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
lua<<EOF
  packer_setup({
    vim.fn.DummyUrl(vim.g.id),
    setup = function()
      vim.g['loaded_' .. vim.g.id] = 2
    end
  })
EOF
  call jetpack#load(g:id)
  call s:assert.equals(g:loaded_{g:id}, 2)
endfunction

function s:suite.packer_style_config()
  let g:id = UniqueId()
  call mkdir(DummyPath(g:id).'/lua', 'p')
  call writefile(
  \ ['return { setup = function() vim.g["loaded_"..vim.g.id] = 1 end }'],
  \ DummyPath(g:id).'/lua/'.g:id.'.lua'
  \ )
  call Git(DummyPath(g:id), ['init', 'add -A', 'commit -m "Initial commit"'])
lua<<EOF
  packer_setup({
    vim.fn.DummyUrl(vim.g.id),
    config = function()
      require(vim.g.id).setup{}
    end
  })
EOF
  call jetpack#load(g:id)
  call s:assert.exists('g:loaded_'.g:id)
endfunction

function! s:suite.pkg_requires() abort
  let g:id1 = UniqueId()
  let g:id2 = UniqueId()
  call mkdir(DummyPath(g:id1).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id1.' = 1'],
  \ DummyPath(g:id1).'/plugin/'.g:id1.'.vim'
  \ )
  call Git(DummyPath(g:id1), ['init', 'add -A', 'commit -m "Initial commit"'])
  call mkdir(DummyPath(g:id2).'/plugin', 'p')
  call writefile(
  \ ['let g:loaded_'.g:id2.' = 1'],
  \ DummyPath(g:id2).'/plugin/'.g:id2.'.vim'
  \ )
  call Git(DummyPath(g:id2), ['init', 'add -A', 'commit -m "Initial commit"'])
lua<<EOF
  packer_setup({
    vim.fn.DummyUrl(vim.g.id1),
    opt = true
  }, {
    vim.fn.DummyUrl(vim.g.id2),
    requires = vim.g.id1,
    opt = true
  })
EOF
  call s:assert.isdirectory(s:optdir.'/'.g:id1)
  call s:assert.isdirectory(s:optdir.'/'.g:id2)
  call s:assert.not_exists('g:loaded_'.g:id1)
  call s:assert.not_exists('g:loaded_'.g:id2)
  call jetpack#load(g:id2)
  call s:assert.exists('g:loaded_'.g:id1)
  call s:assert.exists('g:loaded_'.g:id2)
endfunction
