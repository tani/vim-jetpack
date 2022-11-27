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
  let loaded = luaeval('package.loaded[_A]', a:package)
  call s:assert.not_equals(loaded, v:null)
endfunction

function s:assert.notloaded(package)
  let loaded = luaeval('package.loaded[_A]', a:package)
  call s:assert.equals(loaded, v:null)
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
  packadd goyo.vim
  call s:assert.cmd_exists('Goyo')
  call s:assert.true(s:loaded_goyo_vim)
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
  call feedkeys("i\<Plug>(eskk:toggle)\<Esc>", 'x')
  call feedkeys('', 'x')
  call s:assert.cmd_exists('EskkMap')
  call s:assert.true(s:loaded_eskk_vim)
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

function s:suite.dir_do_option()
  if has('win32')
    call s:assert.skip('')
  endif
  call s:setup(['lotabout/skim', { 'dir': g:vimhome . '/pack/skim', 'do': './install' }])
  call s:assert.isnotdirectory(g:vimhome . '/pack/opt/skim')
  call s:assert.isnotdirectory(g:vimhome . '/pack/src/skim')
  call s:assert.isdirectory(g:vimhome . '/pack/skim')
  call s:assert.filereadable(g:vimhome . '/pack/skim/bin/sk')
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
  call s:setup(['neoclide/coc.nvim', { 'tag': 'v0.0.80' }])
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  let data = json_decode(join(readfile(s:optdir . '/_/package.json')))
  call s:assert.equals(data.version, '0.0.80')
endfunction

function s:suite.branch_option()
  call s:setup(['neoclide/coc.nvim', { 'branch': 'release' }])
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  call s:assert.filereadable(s:optdir . '/_/build/index.js')
endfunction

function s:suite.commit_option()
  call s:setup(['neoclide/coc.nvim', { 'commit': 'ce448a6' }])
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  let data = json_decode(join(readfile(s:optdir . '/_/package.json')))
  call s:assert.equals(data.version, '0.0.80')
endfunction

function s:suite.issue70()
  call s:setup(['s1n7ax/nvim-window-picker'], ['p00f/nvim-ts-rainbow'])
  call s:assert.filereadable(s:optdir . '/_/screenshots')
  call s:assert.isdirectory(s:optdir. '/nvim-ts-rainbow/screenshots')
endfunction

function s:suite.local_plugin()
  let install_path = expand(g:vimhome . '/pack/linkformat.vim')
  call system('git clone --depth 1 https://github.com/uga-rosa/linkformat.vim.git ' . install_path)
  call s:setup([install_path])
  call s:assert.isdirectory(s:optdir . '/linkformat.vim')
  call s:assert.filereadable(s:optdir . '/linkformat.vim/plugin/linkformat.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/linkformat.vim')
  call s:assert.equals(jetpack#get('linkformat.vim').path, install_path)
  packadd linkformat.vim
  call s:assert.cmd_exists('LinkFormatPaste')
endfunction

if !has('nvim')
  finish
endif

lua <<EOL
local packer = require('jetpack.packer')

packer.init({
  package_root = vim.g.vimhome .. '/pack',
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
  lua packer_setup('EdenEast/nightfox.nvim')
  call s:assert.isnotdirectory(s:optdir . '/nightfox.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/nightfox.vim')
endfunction

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
  call s:assert.isdirectory(s:optdir . '/nvim-web-devicons')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/nvim-web-devicons.vim')
  call s:assert.notloaded('nvim-web-devicons')
  call s:assert.true(jetpack#load('nvim-web-devicons'))
  call s:assert.loaded('nvim-web-devicons') " means config is called
  let zsh_icon = luaeval('require("nvim-web-devicons").get_icon("foo.zsh")')
  call s:assert.equals(zsh_icon, '')
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
  call s:assert.isdirectory(s:optdir . '/filetype.nvim')
  call s:assert.notloaded('filetype')
  call s:assert.true(jetpack#load('filetype.nvim'))
  call s:assert.loaded('filetype') " means config is called
  e foo.pn
  lua require('filetype').resolve()
  call s:assert.equals(&ft, 'potion')
endfunction

function s:suite.pkg_setup()
  lua <<EOL
  packer_setup({
    'hrsh7th/vim-searchx',
    setup = function()
      vim.g.searchx = {
        auto_accept = true, -- default: false
      }
    end,
  })
EOL
  call s:assert.isdirectory(s:optdir . '/vim-searchx')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/searchx.vim')
  call s:assert.true(jetpack#load('vim-searchx'))
  call s:assert.equals(g:searchx.auto_accept, v:true) " Default is v:false, so if v:true, setup has been called.
endfunction
