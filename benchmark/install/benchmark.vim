let s:from = expand('<sfile>:p:h') . '/input'
let s:to = expand('<sfile>:p:h') . '/output'
let s:iter = 1000

function NvimLink()
  for i in range(s:iter)
    call v:lua.vim.loop.fs_link(s:from, s:to . string(i))
  endfor
endfunction

function NvimSymlink()
  for i in range(s:iter)
    call v:lua.vim.loop.fs_symlink(s:from, s:to . string(i))
  endfor
endfunction

function Copy()
  for i in range(s:iter)
    call writefile(readfile(s:from, 'b'), s:to . string(i), 'b')
  endfor
endfunction

function SystemCopy()
  for i in range(s:iter)
    call system(printf('cp "%s" "%s"', s:from, s:to . string(i)))
  endfor
endfunction

function SystemLink()
  for i in range(s:iter)
    call system(printf('ln "%s" "%s"', s:from, s:to . string(i)))
  endfor
endfunction

function SystemSymlink()
  for i in range(s:iter)
    call system(printf('ln -s "%s" "%s"', s:from, s:to . string(i)))
  endfor
endfunction
