"=============== JETPACK.vim =================
"      The lightning-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

" Original: https://github.com/vim-jp/vital.vim/blob/1168f6fcbf2074651b62d4ba70b9689c43db8c7d/autoload/vital/__vital__/Data/List.vim#L102-L117
"  License: NYSL, http://www.kmonos.net/nysl/index.en.html
function! s:flatten(list, ...) abort
  let limit = a:0 > 0 ? a:1 : -1
  let memo = []
  if limit == 0
    return a:list
  endif
  let limit -= 1
  for Value in a:list
    let memo +=
          \ type(Value) == type([]) ?
          \   s:flatten(Value, limit) :
          \   [Value]
    unlet! Value
  endfor
  return memo
endfunction

if exists('*flatten')
  function! s:flatten(x)
    return flatten(a:x)
  endfunction
endif

if !exists('g:jetpack#optimization')
  let g:jetpack#optimization = 1
endif

if !exists('g:jetpack#njobs')
  let g:jetpack#njobs = 8
endif

if !exists('g:jetpack#ignore_patterns')
  let g:jetpack#ignore_patterns = [
  \   '/.*',
  \   '/.*/**/*',
  \   '/t/**/*',
  \   '/test/**/*',
  \   '/Makefile*',
  \   '/Gemfile*',
  \   '/Rakefile*',
  \   '/VimFlavor*',
  \   '/README*',
  \   '/LICENSE*',
  \   '/LICENCE*',
  \   '/CONTRIBUTING*',
  \   '/CHANGELOG*',
  \   '/NEWS*',
  \ ]
endif

let s:packages = []

let s:progress_type = {
\   'skip': 'skip',
\   'install': 'install',
\   'update': 'update',
\ }

function s:path(...)
  return expand(join(a:000, '/'))
endfunction

function s:match(a, b)
  return a:a =~# ('\V'.escape(a:b, '\'))
endfunction

function s:substitute(a, b, c)
  return substitute(a:a, '\V' . escape(a:b, '\'), escape(a:c, '\'), '')
endfunction

function! s:files(path) abort
  return filter(glob(a:path . '/**/*', '', 1), '!isdirectory(v:val)')
endfunction

function! s:ignorable(filename) abort
  return filter(copy(g:jetpack#ignore_patterns), 'a:filename =~? glob2regpat(v:val)') != []
endfunction

function! s:progressbar(n) abort
  return '[' . join(map(range(0, 100, 3), {_, v -> v < a:n ? '=' : ' '}), '') . ']'
endfunction

function! s:jobstatus(job) abort
  if has('nvim')
    return jobwait([a:job], 0)[0] == -1 ? 'run' : 'dead'
  endif
  return job_status(a:job)
endfunction

function! s:jobcount(jobs) abort
  return len(filter(copy(a:jobs), 's:jobstatus(v:val) ==# "run"'))
endfunction

function! s:jobwait(jobs, njobs) abort
  let running = s:jobcount(a:jobs)
  while running > a:njobs
    let running = s:jobcount(a:jobs)
  endwhile
endfunction

if has('nvim')
  function! s:jobstart(cmd, cb) abort
    let buf = []
    return jobstart(a:cmd, {
    \   'on_stdout': { _, data -> extend(buf, data) },
    \   'on_stderr': { _, data -> extend(buf, data) },
    \   'on_exit': { -> a:cb(join(buf, "\n")) }
    \ })
  endfunction
else
  " Original: https://github.com/lambdalisue/vital-Whisky/blob/90c715b446993bf5bfcf6f912c20ae514051cbb2/autoload/vital/__vital__/System/Job/Vim.vim#L46
  "  License: https://github.com/lambdalisue/vital-Whisky/blob/90c715b446993bf5bfcf6f912c20ae514051cbb2/LICENSE
  function! s:exit_cb(buf, cb, job, ...) abort
    let ch = job_getchannel(a:job)
    while ch_status(ch) ==# 'open' | sleep 1ms | endwhile
    while ch_status(ch) ==# 'buffered' | sleep 1ms | endwhile
    call a:cb(join(a:buf, "\n"))
  endfunction
  function! s:jobstart(cmd, cb) abort
    let buf = []
    return job_start(a:cmd, {
    \   'out_mode': 'raw',
    \   'out_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'err_mode': 'raw',
    \   'err_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'exit_cb': function('s:exit_cb', [buf, a:cb])
    \ })
  endfunction
endif

function! s:copy(from, to) abort
  call mkdir(fnamemodify(a:to, ':p:h'), 'p')
  let doc = a:from =~# '**/doc/tags*'
  if has('nvim') && !doc
    call v:lua.vim.loop.fs_link(a:from, a:to)
  elseif has('unix') && !doc
    call system(printf('ln -f "%s" "%s"', a:from, a:to))
  else
    call writefile(readfile(a:from, 'b'), a:to, 'b')
    call setfperm(a:to, getfperm(a:from))
  endif
endfunction

function! s:setbufline(lnum, text, ...) abort
  call setbufline(bufnr('JetpackStatus'), a:lnum, a:text)
  redraw
endfunction

function! s:setupbuf() abort
  execute 'silent! bdelete! ' . bufnr('JetpackStatus')
  40vnew +setlocal\ buftype=nofile\ nobuflisted\ noswapfile\ nonumber\ nowrap JetpackStatus
  syntax clear
  syntax match jetpackProgress /^[A-Z][a-z]*ing/
  syntax match jetpackComplete /^[A-Z][a-z]*ed/
  syntax keyword jetpackSkipped ^Skipped
  highlight def link jetpackProgress DiffChange
  highlight def link jetpackComplete DiffAdd
  highlight def link jetpackSkipped DiffDelete
  redraw
endfunction

function! jetpack#install(...) abort
  call s:setupbuf()
  let jobs = []
  for i in range(len(s:packages))
    let pkg = s:packages[i]
    call s:setbufline(1, printf('Install Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:packages)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:packages) * 100))
    call s:setbufline(i+3, printf('Installing %s ...', pkg.name))
    if (a:0 > 0 && index(a:000, pkg.name) < 0) || isdirectory(pkg.path)
      call s:setbufline(i+3, printf('Skipped %s', pkg.name))
      continue
    endif
    let cmd = ['git', 'clone']
    if !has_key(pkg, 'commit')
      call extend(cmd, ['--depth', '1', '--recursive'])
    endif
    if has_key(pkg, 'branch') || has_key(pkg, 'tag')
      call extend(cmd, ['-b', get(pkg, 'branch', get(pkg, 'tag'))])
    endif
    call extend(cmd, [pkg.url, pkg.path])
    let job = s:jobstart(cmd, function({ i, pkg, output -> [
    \   extend(pkg, {
    \     'progress': {
    \       'type': s:progress_type.install,
    \       'output': output
    \     }
    \   }),
    \   s:setbufline(i+3, printf('Installed %s', pkg.name))
    \ ] }, [i, pkg]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
endfunction

function! jetpack#checkout(...) abort
  call s:setupbuf()
  for i in range(len(s:packages))
    let pkg = s:packages[i]
    call s:setbufline(1, printf('Checkout Plugins (%d / %d)', i, len(s:packages)))
    call s:setbufline(2, s:progressbar((0.0 + i) / len(s:packages) * 100))
    if (a:0 > 0 && index(a:000, pkg.name) < 0) || !isdirectory(pkg.path) || !has_key(pkg, 'commit')
      call s:setbufline(i+3, printf('Skipped %s', pkg.name))
      continue
    endif
    call system(printf('git -C "%s" switch "-"', pkg.path))
    call system(printf('git -C "%s" checkout "%s"', pkg.path, pkg.commit))
    call s:setbufline(i+3, printf('Checkout %s in %s', pkg.commit, pkg.name))
  endfor
endfunction

function! jetpack#update(...) abort
  call s:setupbuf()
  let jobs = []
  for i in range(len(s:packages))
    let pkg = s:packages[i]
    call s:setbufline(1, printf('Update Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:packages)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:packages) * 100))
    call s:setbufline(i+3, printf('Updating %s ...', pkg.name))
    if pkg.progress.type ==# s:progress_type.install || (a:0 > 0 && index(a:000, pkg.name) < 0) || (get(pkg, 'frozen') || !isdirectory(pkg.path))
      call s:setbufline(i+3, printf('Skipped %s', pkg.name))
      continue
    endif
    let cmd = ['git', '-C', pkg.path, 'pull', '--rebase']
    let job = s:jobstart(cmd, function({ i, pkg, output -> [
    \   extend(pkg, {
    \     'progress': {
    \       'type': s:progress_type.update,
    \       'output': output
    \     }
    \   }),
    \   s:setbufline(i+3, printf('Updated %s', pkg.name))
    \ ] }, [i, pkg]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
endfunction

function! jetpack#clean() abort
  for pkg in s:packages
    if isdirectory(pkg.path) && has_key(pkg, 'commit')
      if system(printf('git -c "%s" cat-file -t %s', pkg.path, pkg.commit)) !~# 'commit'
        call delete(pkg.path)
      endif
    endif
    if isdirectory(pkg.path) && (has_key(pkg, 'branch') || has_key(pkg, 'tag'))
      let branch = trim(system(printf('git -C "%s" rev-parse --abbrev-ref HEAD', pkg.path)))
      if get(pkg, 'branch', get(pkg, 'tag')) != branch
        call delete(pkg.path, 'rf')
      endif
    endif
  endfor
endfunction

function! jetpack#bundle() abort
  call s:setupbuf()
  let bundle = []
  let unbundle = s:packages
  if g:jetpack#optimization >= 1
    let bundle = filter(copy(s:packages), 's:match(v:val["path"], s:srcdir) && !get(v:val, "opt") && !has_key(v:val, "do")')
    let unbundle = filter(copy(s:packages), 's:match(v:val["path"], s:srcdir) && (get(v:val, "opt") || has_key(v:val, "do"))') 
  endif

  call delete(s:optdir, 'rf')
  let destdir = s:path(s:optdir, '_')
  " Merge plugins if possible.
  let merged_count = 0
  let merged_files = {}
  for i in range(len(bundle))
    let pkg = bundle[i]
    call s:setbufline(1, printf('Merging Plugins (%d / %d)', merged_count, len(s:packages)))
    call s:setbufline(2, s:progressbar(1.0 * merged_count / len(s:packages) * 100))
    let srcdir = s:path(pkg.path, get(pkg, 'rtp', ''))
    let srcfiles = filter(s:files(srcdir), '!s:ignorable(s:substitute(v:val, srcdir, ""))')
    let destfiles = map(copy(srcfiles), 's:substitute(v:val, srcdir, destdir)')
    if g:jetpack#optimization == 1
      if filter(copy(destfiles), 'has_key(merged_files, v:val)') != []
        call add(unbundle, pkg)
        continue
      endif
    endif
    for i in range(0, len(srcfiles) - 1)
      call s:copy(srcfiles[i], destfiles[i])
      let merged_files[destfiles[i]] = v:true
    endfor
    call s:setbufline(merged_count+3, printf('Merged %s ...', pkg.name))
    let merged_count += 1
  endfor

  " Copy plugins.
  for i in range(len(unbundle))
    let pkg = unbundle[i]
    call s:setbufline(1, printf('Copy Plugins (%d / %d)', i+merged_count, len(s:packages)))
    call s:setbufline(2, s:progressbar(1.0 * (i+merged_count) / len(s:packages) * 100))
    let srcdir = s:path(pkg.path, get(pkg, 'rtp', ''))
    let destdir = s:path(s:optdir, pkg.name)
    for srcfile in s:files(srcdir)
      let destfile = s:substitute(srcfile, srcdir, destdir)
      call s:copy(srcfile, s:substitute(srcfile, srcdir, destdir))
    endfor
    call s:setbufline(i+merged_count+3, printf('Copied %s ...', pkg.name))
  endfor
endfunction

function! s:display() abort
  call s:setupbuf()
  let msg = {}
  let msg[s:progress_type.skip] = 'Skipped'
  let msg[s:progress_type.install] = 'Installed'
  let msg[s:progress_type.update] = 'Updated'

  let line_count = 1
  for pkg in s:packages
    let output = pkg.progress.output
    let output = substitute(output, '\r\n\|\r', '\n', 'g')
    let output = substitute(output, '^From.\{-}\zs\n\s*', '/compare/', '')

    call s:setbufline(line_count, printf('%s %s', msg[pkg.progress.type], pkg.name))
    let line_count += 1
    for o in split(output, '\n')
      if o !=# ''
        call s:setbufline(line_count, printf('  %s', o))
        let line_count += 1
      endif
    endfor
    call s:setbufline(line_count, '')
    let line_count += 1
  endfor
endfunction

function! jetpack#postupdate() abort
  silent! packadd _
  for pkg in s:packages
    if !has_key(pkg, 'do')
      continue
    endif
    let pwd = getcwd()
    if !s:match(pkg.path, s:srcdir)
      call chdir(pkg.path)
    else
      call chdir(s:path(s:optdir, pkg.name))
      execute 'silent! packadd ' . pkg.name
    endif
    if type(pkg.do) == v:t_func
      call pkg.do()
    endif
    if type(pkg.do) != v:t_string
      continue
    endif
    if pkg.do =~# '^:'
      execute pkg.do
    else
      call system(pkg.do)
    endif
    call chdir(pwd)
  endfor
  silent! helptags ALL
endfunction

function! jetpack#sync() abort
  call jetpack#clean()
  call jetpack#install()
  call jetpack#update()
  call jetpack#checkout()
  call jetpack#bundle()
  call s:display()
  call jetpack#postupdate()
endfunction

function! jetpack#add(plugin, ...) abort
  let opts = a:0 > 0 ? a:1 : {}
  let name = get(opts, 'as', fnamemodify(a:plugin, ':t'))
  let path = get(opts, 'dir', s:path(s:srcdir,  name))
  let url = (a:plugin !~# ':' ? 'https://github.com/' : '') . a:plugin
  let opt = has_key(opts, 'for') || has_key(opts, 'on') || get(opts, 'opt')
  let pkg  = extend(opts, {
  \   'url': url,
  \   'opt': opt,
  \   'name': name,
  \   'path': path,
  \   'progress': {
  \     'type': s:progress_type.skip,
  \     'output': 'Skipped',
  \   },
  \ })
  call add(s:packages, pkg)
endfunction

function! jetpack#begin(...) abort
  let s:packages = []
  if has('nvim')
    let s:home = s:path(stdpath('data'), 'site')
  elseif has('win32') || has('win64')
    let s:home = expand('~/vimfiles')
  else
    let s:home = expand('~/.vim')
  endif
  if a:0 != 0
    let s:home = expand(a:1)
    execute 'set packpath^=' . s:home
  endif
  let s:optdir = s:path(s:home, 'pack', 'jetpack', 'opt')
  let s:srcdir = s:path(s:home, 'pack', 'jetpack', 'src')
  command! -nargs=+ -bar Jetpack call jetpack#add(<args>)
endfunction

" Original: https://github.com/junegunn/vim-plug/blob/e300178a0e2fb04b56de8957281837f13ecf0b27/plug.vim#L683-L693
"  License: MIT, https://raw.githubusercontent.com/junegunn/vim-plug/88cc9d78687dd309389819f85b39368a4fd745c8/LICENSE
function! s:lod_map(map, name, with_prefix, prefix)
  execute 'packadd ' . a:name
  let extra = ''
  let code = getchar(0)
  while (code != 0 && code != 27)
    let extra .= nr2char(code)
    let code = getchar(0)
  endwhile
  if a:with_prefix
    let prefix = v:count ? v:count : ''
    let prefix .= '"'.v:register.a:prefix
    if mode(1) ==# 'no'
      if v:operator ==# 'c'
        let prefix = "\<Esc>" . prefix
      endif
      let prefix .= v:operator
    endif
    call feedkeys(prefix, 'n')
  endif
  call feedkeys(substitute(a:map, '^<Plug>', "\<Plug>", 'i') . extra)
endfunction

function! jetpack#end() abort
  delcommand Jetpack
  command! -bar JetpackSync call jetpack#sync()
  syntax off
  filetype plugin indent off
  augroup Jetpack
    autocmd!
  augroup END
  for pkg in s:packages
    if pkg.opt
      for it in s:flatten([get(pkg, 'for', [])])
        execute printf('autocmd Jetpack FileType %s ++once ++nested silent! packadd %s', it, pkg.name)
      endfor
      for it in s:flatten([get(pkg, 'on', [])])
        if it =~? '^<Plug>'
          " Original: https://github.com/junegunn/vim-plug/blob/88cc9d78687dd309389819f85b39368a4fd745c8/plug.vim#L262-L269
          "  License: MIT, https://raw.githubusercontent.com/junegunn/vim-plug/88cc9d78687dd309389819f85b39368a4fd745c8/LICENSE
          for [mode, map_prefix, key_prefix] in [['i', '<C-\><C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
            execute printf(
            \ '%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, %s, "%s")<CR>',
            \ mode, it, map_prefix, string(it), string(pkg.name), mode !=# 'i', key_prefix)
          endfor
        else
          let cmd = substitute(it, '^:', '', '')
          execute printf('autocmd Jetpack CmdUndefined %s ++once ++nested silent! packadd %s', cmd, pkg.name)
        endif
      endfor
      let event = substitute(substitute(pkg.name, '\W\+', '_', 'g'), '\(^\|_\)\(.\)', '\u\2', 'g')
      execute printf('autocmd Jetpack SourcePre **/pack/jetpack/opt/%s/* ++once ++nested doautocmd User Jetpack%sPre', pkg.name, event)
      execute printf('autocmd Jetpack SourcePost **/pack/jetpack/opt/%s/* ++once ++nested doautocmd User Jetpack%sPost', pkg.name, event)
      execute printf('autocmd Jetpack User Jetpack%sPre :', event)
      execute printf('autocmd Jetpack User Jetpack%sPost :', event)
      " Deprecated autocommand (show a message if used)
      execute printf('autocmd Jetpack SourcePost **/pack/jetpack/opt/%s/* ++once ++nested doautocmd User Jetpack%s', pkg.name, event)
      execute printf('autocmd Jetpack User Jetpack%sPost ++once call s:warn_deprecated_autocmd(%s)', event, string(event))
    elseif isdirectory(s:path(s:optdir, pkg.name))
      execute 'silent! packadd! ' . pkg.name
    endif
  endfor
  silent! packadd! _
  syntax enable
  filetype plugin indent on
endfunction

function! s:warn_deprecated_autocmd(event) abort
  if exists('#User#Jetpack' . a:event)
    echohl ErrorMsg
    echomsg printf('Jetpack%s is deprecated. Please use Jetpack%sPost.', a:event, a:event)
    echohl None
  endif
  execute printf('autocmd User Jetpack%s :', a:event)
endfunction

function! jetpack#tap(name) abort
  for pkg in s:packages
    if pkg.name ==# a:name
      return isdirectory(pkg.path)
    endif
  endfor
  return 0
endfunction

function! jetpack#names() abort
  return map(copy(s:packages), 'v:val["name"]')
endfunction

function! jetpack#get(name) abort
  for pkg in s:packages
    if pkg.name ==# a:name
      return pkg
    endif
  endfor
  return {}
endfunction

if has('nvim')
lua<<EOF
  local _require = require
  function require(name)
    local event = vim.fn.substitute(name, [[\W\+]], [[_]], 'g')
    event = vim.fn.substitute(event, [[\(^\|_\)\(.\)]], [[\u\2]], 'g')
    vim.cmd(string.format('doautocmd User Jetpack%sPre', event))
    local module = _require(name)
    vim.cmd(string.format('doautocmd User Jetpack%sPost', event))
    -- Deprecated
    vim.cmd(string.format('doautocmd User Jetpack%s', event))
    return module
  end
EOF
endif
