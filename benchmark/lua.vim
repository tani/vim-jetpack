set packpath=
execute 'set runtimepath-=' . expand('~/.vim')
call execute(printf('source %s/plugin/jetpack.vim', expand('<sfile>:p:h')))

function s:fallback(val, default)
  return empty(a:val) ? a:default : a:val
endfunction
let g:jetpack_copy_method = s:fallback(getenv('JETPACK_COPY_METHOD'), 'system')
let g:jetpack_download_method = s:fallback(getenv('JETPACK_DOWNLOAD_METHOD'), 'git')

let g:vimhome = substitute(expand('<sfile>:p:h'), '\', '/', 'g')
let s:optdir =  g:vimhome . '/pack/jetpack/opt'
let s:srcdir =  g:vimhome . '/pack/jetpack/src'

lua<<EOF
require('jetpack.packer').init({
  package_root = vim.g.vimhome .. '/pack'
})
require('jetpack.packer').startup(function(use)
  use {'EdenEast/nightfox.nvim', config = function()
    vim.command('colorscheme nightfox')
  end}
end)
EOF
