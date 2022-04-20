"=============== JETPACK.vim =================
"      The lightning-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:jetpack#optimization =
  \ get(g:, 'jetpack#optimization', 1)

let g:jetpack#njobs =
  \ get(g:, 'jetpack#njobs', 8)

let g:jetpack#ignore_patterns =
  \ get(g:, 'jetpack#ignore_patterns', [
  \   '/.*',
  \   '/.*/**/*',
  \   '/doc/tags*',
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
  \ ])

let g:jetpack#copy_method =
  \ get(g:, 'jetpack#copy_method', 'system')
  " sytem    : cp/ xcopy
  " copy     : readfile and writefile
  " symlink  : fs_symlink (nvim only)
  " hardlink : fs_link (nvim only)

let s:packages = []

let s:progress_type = {
\   'skip': 'skip',
\   'install': 'install',
\   'update': 'update',
\ }

" Original: https://github.com/vim-jp/vital.vim/blob/1168f6fcbf2074651b62d4ba70b9689c43db8c7d/autoload/vital/__vital__/Data/List.vim#L102-L117
"  License: NYSL, http://www.kmonos.net/nysl/index.en.html
function! s:flatten(list, ...) abort
  if exists('*flatten')
    return flatten(a:list)
  endif
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

function s:path(...)
  return expand(join(a:000, '/'))
endfunction

function! s:files(path) abort
  return filter(glob(a:path . '/**/*', '', 1), { _, val -> !isdirectory(val)})
endfunction

function! s:ignorable(filename) abort
  return filter(copy(g:jetpack#ignore_patterns), { _, val -> a:filename =~? glob2regpat(val) }) != []
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
  return len(filter(copy(a:jobs), { _, val -> s:jobstatus(val) ==# 'run' }))
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
  call mkdir(a:to, 'p')
  if g:jetpack#copy_method !=# 'system'
    for src in s:files(a:from)
      let dest = substitute(src, '\V' . escape(a:from, '\'), escape(a:to, '\'), '')
      call mkdir(fnamemodify(dest, ':p:h'), 'p')
      if g:jetpack#copy_method ==# 'copy'
        call writefile(readfile(src, 'b'), dest, 'b')
      elseif g:jetpack#copy_method ==# 'hardlink'
        call v:lua.vim.loop.fs_link(src, dest)
      elseif g:jetpack#copy_method ==# 'symlink'
        call v:lua.vim.loop.fs_symlink(src, dest)
      endif
    endfor
  elseif has('unix')
    call system(printf('cp -R "%s/." "%s"', a:from, a:to))
  elseif has('win32') || has('win64')
    call system(printf('xcopy "%s" "%s" /E /Y', a:from, a:to))
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
    if pkg.progress.type ==# s:progress_type.install
       \ || (a:0 > 0 && index(a:000, pkg.name) < 0)
       \ || (get(pkg, 'frozen')
       \ || !isdirectory(pkg.path))
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
    if isdirectory(pkg.path) 
      if has_key(pkg, 'commit')
        if system(printf('git -c "%s" cat-file -t %s', pkg.path, pkg.commit)) !~# 'commit'
          call delete(pkg.path)
        endif
      elseif has_key(pkg, 'branch') || has_key(pkg, 'tag')
        let branch = trim(system(printf('git -C "%s" rev-parse --abbrev-ref HEAD', pkg.path)))
        if get(pkg, 'branch', get(pkg, 'tag')) != branch
          call delete(pkg.path, 'rf')
        endif
      endif 
    endif
  endfor
endfunction

function! jetpack#bundle() abort
  call s:setupbuf()
  let bundle = []
  let unbundle = s:packages
  if g:jetpack#optimization == 1
    let unbundle = []
    for pkg in s:packages
      if get(pkg, 'opt') || has_key(pkg, 'do') || has_key(pkg, 'dir')
        call add(unbundle, pkg)
      else
        call add(bundle, pkg)
      endif
    endfor
  endif

  call delete(s:optdir, 'rf')
  let destdir = s:path(s:optdir, '_')

  " Merge plugins if possible.
  let merged_count = 0
  let merged_files = {}
  for pkg in bundle
    call s:setbufline(1, printf('Merging Plugins (%d / %d)', merged_count, len(s:packages)))
    call s:setbufline(2, s:progressbar(1.0 * merged_count / len(s:packages) * 100))
    let srcdir = s:path(pkg.path, get(pkg, 'rtp', ''))

    let files = map(s:files(srcdir), {_, file -> file[len(srcdir):]})
    let files = filter(files, { _, file -> !s:ignorable(file) })
    let conflicted = v:false
    for file in files
      if has_key(merged_files, file)
        let conflicted = v:true
        break
      endif
    endfor
    if conflicted
      call add(unbundle, pkg)
    else
      for file in files
        let merged_files[file] = v:true
      endfor
      call s:copy(srcdir, destdir)
      call s:setbufline(merged_count+3, printf('Merged %s ...', pkg.name))
      let merged_count += 1
    endif
  endfor

  " Copy plugins.
  for i in range(len(unbundle))
    let pkg = unbundle[i]
    call s:setbufline(1, printf('Copying Plugins (%d / %d)', i+merged_count, len(s:packages)))
    call s:setbufline(2, s:progressbar(1.0 * (i+merged_count) / len(s:packages) * 100))
    if has_key(pkg, 'dir')
      call s:setbufline(i+merged_count+3, printf('Skipped %s ...', pkg.name))
    else
      let srcdir = s:path(pkg.path, get(pkg, 'rtp', ''))
      let destdir = s:path(s:optdir, pkg.name)
      call s:copy(srcdir, destdir)
      call s:setbufline(i+merged_count+3, printf('Copied %s ...', pkg.name))
    endif
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
    if has_key(pkg, 'dir')
      call chdir(pkg.path)
    else
      execute 'silent! packadd ' . pkg.name
      call chdir(s:path(s:optdir, pkg.name))
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
  for dir in glob(s:optdir . '/*/doc', '', 1)
    execute 'silent! helptags ' . dir
  endfor
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
    execute 'set runtimepath^=' . s:home
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
    if has_key(pkg, 'dir')
      let &runtimepath .= printf(',%s/%s', pkg.dir, get(pkg, 'rtp', ''))
      continue
    endif
    if pkg.opt
      for it in s:flatten([get(pkg, 'for', [])])
        execute printf('autocmd Jetpack FileType %s ++once ++nested silent! packadd %s', it, pkg.name)
      endfor
      for it in s:flatten([get(pkg, 'on', [])])
        if it =~? '^<Plug>'
          execute printf('inoremap <silent> %s <C-\><C-O>:<C-U>call <SID>lod_map(%s, %s, 0, "")<CR>', it, string(it), string(pkg.name))
          execute printf('nnoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "")<CR>', it, string(it), string(pkg.name))
          execute printf('vnoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "gv")<CR>', it, string(it), string(pkg.name))
          execute printf('onoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "")<CR>', it, string(it), string(pkg.name))
        elseif exists('##'.substitute(it, ' .*', '', ''))
          let it .= (it =~? ' ' ? '' : ' *')
          execute printf('autocmd Jetpack %s ++once ++nested silent! packadd %s', it, pkg.name)
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
    elseif isdirectory(s:path(s:optdir, pkg.name))
      execute 'silent! packadd! ' . pkg.name
    endif
  endfor
  silent! packadd! _
  syntax enable
  filetype plugin indent on
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
  return map(copy(s:packages), { _, val -> get(val, 'name') })
endfunction

function! jetpack#get(name) abort
  for pkg in s:packages
    if pkg.name ==# a:name
      return pkg
    endif
  endfor
  return {}
endfunction
