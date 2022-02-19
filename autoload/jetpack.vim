"=============== JETPACK.vim =================
"      The lightnig-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:jetpack#optimization = 1
let g:jetpack#njobs = 8

let s:home = expand(has('nvim') ? '~/.local/share/nvim/site' : '~/.vim')
let s:optdir = s:home . '/pack/jetpack/opt'
let s:srcdir = s:home . '/pack/jetpack/src'

let s:pkgs = []
let s:ignores = [
\   '**/.*',
\   '**/.*/**/*',
\   '**/t/**/*',
\   '**/test/**/*',
\   '**/VimFlavor*',
\   '**/Flavorfile*',
\   '**/README*',
\   '**/Rakefile*',
\   '**/Gemfile*',
\   '**/Makefile*',
\   '**/LICENSE*',
\   '**/LICENCE*',
\   '**/CONTRIBUTING*',
\   '**/CHANGELOG*',
\   '**/NEWS*',
\ ]

let s:progress_type = {
\   'skip': 'skip',
\   'install': 'install',
\   'update': 'update',
\ }

function! s:files(path) abort
  return filter(glob(a:path . '/**/*', '', 1), '!isdirectory(v:val)')
endfunction

function! s:ignorable(filename) abort
  return filter(copy(s:ignores), 'a:filename =~ glob2regpat(v:val)') != []
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
  " See https://github.com/lambdalisue/vital-Whisky/blob/90c715b446993bf5bfcf6f912c20ae514051cbb2/autoload/vital/__vital__/System/Job/Vim.vim#L46
  " See https://github.com/lambdalisue/vital-Whisky/blob/90c715b446993bf5bfcf6f912c20ae514051cbb2/LICENSE
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
  if has('nvim')
    call v:lua.vim.loop.fs_symlink(a:from, a:to)
  else
    call writefile(readfile(a:from, 'b'), a:to, 'b')
  endif
endfunction

function! s:syntax() abort
  syntax clear
  syntax match jetpackProgress /[A-Z][a-z]*ing/
  syntax match jetpackComplete /[A-Z][a-z]*ed/
  syntax keyword jetpackSkipped Skipped
  highlight def link jetpackProgress DiffChange
  highlight def link jetpackComplete DiffAdd
  highlight def link jetpackSkipped DiffDelete
endfunction

function! s:setbufline(lnum, text, ...) abort
  call setbufline('JetpackStatus', a:lnum, a:text)
  redraw
endfunction

function! s:setupbuf() abort
  silent! execute 'bdelete! ' . bufnr('JetpackStatus')
  silent 40vnew +setlocal\ buftype=nofile\ nobuflisted\ noswapfile\ nonumber\ nowrap JetpackStatus
  call s:syntax()
  redraw
endfunction

function! jetpack#install(...) abort
  call s:setupbuf()
  let jobs = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    call s:setbufline(1, printf('Install Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:pkgs)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Installing %s ...', pkg.name))
    if (a:0 > 0 && index(a:000, pkg.name) < 0) || isdirectory(pkg.path)
      call s:setbufline(i+3, printf('Skipped %s', pkg.name))
      continue
    endif

    let cmd = ['git', 'clone', '--depth', '1']
    if type(pkg.branch) == v:t_string
      call extend(cmd, ['-b', pkg.branch])
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

function! jetpack#update(...) abort
  call s:setupbuf()
  let jobs = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    call s:setbufline(1, printf('Update Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:pkgs)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Updating %s ...', pkg.name))
    if pkg.progress.type ==# s:progress_type.install || (a:0 > 0 && index(a:000, pkg.name) < 0) || (pkg.frozen || !isdirectory(pkg.path))
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
  for pkg in s:pkgs
    if isdirectory(pkg.path) && type(pkg.branch) == v:t_string
      let branch = system(printf('git -C "%s" rev-parse --abbrev-ref HEAD', pkg.path))
      if pkg.branch != branch
        call delete(pkg.path, 'rf')
      endif
    endif
  endfor
endfunction

function! jetpack#bundle() abort
  call s:setupbuf()

  let bundle = []
  let unbundle = s:pkgs
  if g:jetpack#optimization >= 1
    let bundle = filter(copy(s:pkgs), '!v:val["opt"]')
    let unbundle = filter(copy(s:pkgs), 'v:val["opt"]') 
  endif

  call delete(s:optdir, 'rf')
  let destdir = s:optdir . '/_'

  " Merge plugins if possible.
  let merged_count = 0
  let merged_files = {}
  for i in range(len(bundle))
    let pkg = bundle[i]
    call s:setbufline(1, printf('Merging Plugins (%d / %d)', merged_count, len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * merged_count / len(s:pkgs) * 100))
    let srcdir = pkg.path . '/' . pkg.subdir
    let srcfiles = filter(s:files(srcdir), '!s:ignorable(substitute(v:val, srcdir, "", ""))')
    let destfiles = map(copy(srcfiles), 'substitute(v:val, srcdir, destdir, "")')
    let dupfiles = filter(copy(destfiles), 'has_key(merged_files, v:val)')
    if g:jetpack#optimization == 1 && dupfiles != []
      call add(unbundle, pkg)
      continue
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
    call s:setbufline(1, printf('Copy Plugins (%d / %d)', i+merged_count, len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * (i+merged_count) / len(s:pkgs) * 100))
    let srcdir = pkg.path . '/' . pkg.subdir
    let destdir = s:optdir . '/' . pkg.name
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      call s:copy(srcfile, substitute(srcfile, srcdir, destdir, ''))
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
  for pkg in s:pkgs
    call s:setbufline(line_count, printf('%s %s', msg[pkg.progress.type], pkg.name))
    let line_count += 1

    let output = pkg.progress.output
    let output = substitute(output, '\r\n\|\r', '\n', 'g')

    if pkg.progress.type ==# s:progress_type.update
      let from_to = matchstr(output, 'Updating\s*\zs[^\n]\+')
      if from_to !=# ''
        call s:setbufline(line_count, printf('  Changes %s/compare/%s', pkg.url, from_to))
        let line_count += 1
      endif
    endif

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
  for pkg in s:pkgs
    let pwd = getcwd()
    if pkg.dir
      execute printf('cd %s', pkg.path)
    elseif isdirectory(s:optdir . '/' . pkg.name)
      execute printf('cd %s/%s', s:optdir, pkg.name)
    else
      execute printf('cd %s/_', s:optdir)
    endif
    execute 'silent! packadd ' . pkg.name
    if type(pkg.hook) == v:t_func
      call pkg.hook()
    endif
    if type(pkg.hook) == v:t_string
      if pkg.hook =~# '^:'
        execute pkg.hook
      else
        call system(pkg.hook)
      endif
    endif
    execute printf('cd %s', pwd)
  endfor
  silent! helptags ALL
endfunction

function! jetpack#sync() abort
  echomsg 'Cleaning up plugins ...'
  call jetpack#clean()
  echomsg 'Installing plugins ...'
  call jetpack#install()
  echomsg 'Updating plugins ...'
  call jetpack#update()
  echomsg 'Bundling plugins ...'
  call jetpack#bundle()
  echomsg 'Display results ...'
  call s:display()
  echomsg 'Running the post-update hooks ...'
  call jetpack#postupdate()
  echomsg 'Complete'
endfunction
command! JetpackSync call jetpack#sync()

function! jetpack#add(plugin, ...) abort
  let opts = a:0 > 0 ? a:1 : {}
  let name = get(opts, 'as', fnamemodify(a:plugin, ':t'))
  let path = get(opts, 'dir', s:srcdir . '/' . name)
  let pkg  = {
  \  'url': a:plugin =~ ':' ? a:plugin : 'https://github.com/' . a:plugin,
  \  'branch': get(opts, 'branch', get(opts, 'tag')),
  \  'hook': get(opts, 'do'),
  \  'subdir': get(opts, 'rtp', '.'),
  \  'dir': has_key(opts, 'dir'),
  \  'name': name,
  \  'frozen': get(opts, 'frozen'),
  \  'path': path,
  \  'opt': get(opts, 'opt'),
  \   'progress': {
  \     'type': s:progress_type.skip,
  \     'output': 'Skipped',
  \   },
  \ }
  for it in flatten([get(opts, 'for', [])])
    let pkg.opt = 1
    execute printf('autocmd FileType %s silent! packadd %s', it, name)
  endfor
  for it in flatten([get(opts, 'on', [])])
    let pkg.opt = 1
    if it =~? '^<Plug>'
      execute printf("nnoremap %s :execute '".'silent! packadd %s \| call feedkeys("\%s")'."'<CR>", it, name, it)
    else
      execute printf('autocmd CmdUndefined %s silent! packadd %s', substitute(it, '^:', '', ''), name)
    endif
  endfor
  if isdirectory(s:optdir . '/' . name)
    execute 'silent! packadd! ' . name
  endif
  call add(s:pkgs, pkg)
endfunction

function! jetpack#begin(...) abort
  syntax off
  filetype off
  command! -nargs=+ Jetpack call jetpack#add(<args>)
  let s:home = a:0 != 0 ? a:1 : s:home
  let s:optdir = s:home . '/pack/jetpack/opt'
  let s:srcdir = s:home . '/pack/jetpack/src'
  let s:pkgs = []
  execute 'set packpath^=' . s:home
endfunction

function! jetpack#end() abort
  syntax enable
  filetype plugin indent on
  delcommand Jetpack
  silent! packadd! _
endfunction

function! jetpack#tap(name) abort
  return isdirectory(s:srcdir . '/'. a:name)
endfunction
