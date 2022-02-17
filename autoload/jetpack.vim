"=============== JETPACK.vim =================
"      The lightnig-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:jetpack#optimization = 1
let g:jetpack#njobs = 8
let g:jetpack#verbose = 0

let s:home = expand(has('nvim') ? '~/.local/share/nvim/site' : '~/.vim')
let s:optdir = s:home .. '/pack/jetpack/opt'
let s:srcdir = s:home .. '/pack/jetpack/src'

let s:loaded = {}
let s:pkgs = []
let s:ignores = [
  \ '**/.*',
  \ '**/.*/**/*',
  \ '**/t/**/*',
  \ '**/test/**/*',
  \ '**/VimFlavor*',
  \ '**/Flavorfile*',
  \ '**/README*',
  \ '**/Rakefile*',
  \ '**/Gemfile*',
  \ '**/Makefile*',
  \ '**/LICENSE*',
  \ '**/LICENCE*',
  \ '**/CONTRIBUTING*',
  \ '**/CHANGELOG*',
  \ '**/NEWS*',
  \ ]

let s:events = [
  \ 'BufNewFile', 'BufReadPre', 'BufRead', 'BufReadPost', 'BufReadCmd',
  \ 'FileReadPre', 'FileReadPost', 'FileReadCmd', 'FilterReadPre',
  \ 'FilterReadPost', 'StdinReadPre', 'StdinReadPost', 'BufWrite',
  \ 'BufWritePre', 'BufWritePost', 'BufWriteCmd', 'FileWritePre',
  \ 'FileWritePost', 'FileWriteCmd', 'FileAppendPre', 'FileAppendPost',
  \ 'FileAppendCmd', 'FilterWritePre', 'FilterWritePost', 'BufAdd', 'BufCreate',
  \ 'BufDelete', 'BufWipeout', 'BufFilePre', 'BufFilePost', 'BufEnter',
  \ 'BufLeave', 'BufWinEnter', 'BufWinLeave', 'BufUnload', 'BufHidden',
  \ 'BufNew', 'SwapExists', 'FileType', 'Syntax', 'EncodingChanged',
  \ 'TermChanged', 'VimEnter', 'GUIEnter', 'GUIFailed', 'TermResponse',
  \ 'QuitPre', 'VimLeavePre', 'VimLeave', 'FileChangedShell',
  \ 'FileChangedShellPost', 'FileChangedRO', 'ShellCmdPost', 'ShellFilterPost',
  \ 'FuncUndefined', 'SpellFileMissing', 'SourcePre', 'SourceCmd', 'VimResized',
  \ 'FocusGained', 'FocusLost', 'CursorHold', 'CursorHoldI', 'CursorMoved',
  \ 'CursorMovedI', 'WinEnter', 'WinLeave', 'TabEnter', 'TabLeave',
  \ 'CmdwinEnter', 'CmdwinLeave', 'InsertEnter', 'InsertChange', 'InsertLeave',
  \ 'InsertCharPre', 'TextChanged', 'TextChangedI', 'ColorScheme',
  \ 'RemoteReply', 'QuickFixCmdPre', 'QuickFixCmdPost', 'SessionLoadPost',
  \ 'MenuPopup', 'CompleteDone', 'User'
  \ ]

function s:files(path)
  let files = []
  for item in glob(a:path .. '/**/*', '', 1)
    if !isdirectory(item)
      call add(files, item)
    endif
  endfor
  return files
endfunction

function s:ignorable(filename)
  for ignore in s:ignores
    if a:filename =~ glob2regpat(ignore)
      return 1
    endif
  endfor
  return 0
endfunction

function s:progressbar(n)
  return '[' . join(map(range(0, 100, 3), {_, v -> v < a:n ? '=' : ' '}), '') . ']'
endfunction

function s:jobstatus(job)
  if has('nvim')
    return jobwait([a:job], 0)[0] == -1 ? 'run' : 'dead'
  endif
  return job_status(a:job)
endfunction

function s:jobcount(jobs)
  return len(filter(copy(a:jobs), {_, v -> s:jobstatus(v) == 'run'}))
endfunction

function s:jobwait(jobs, njobs)
  let running = s:jobcount(a:jobs)
  while running > a:njobs
    let running = s:jobcount(a:jobs)
  endwhile
endfunction

function s:jobstart(cmd, cb)
  if g:jetpack#verbose
    echomsg 'jobstart: ' .. string(a:cmd)
  endif
  if has('nvim')
    return jobstart(a:cmd, { 'on_exit': a:cb })
  endif
  return job_start(a:cmd, { 'exit_cb': a:cb })
endfunction

function s:copy(from, to)
  if has('nvim')
    call v:lua.vim.loop.fs_link(a:from, a:to)
  else
    let blob = readfile(a:from, 'b')
    call writefile(blob, a:to, 'b')
  endif
endfunction

function s:syntax()
  syntax clear
  syntax keyword jetpackProgress Installing
  syntax keyword jetpackProgress Updating
  syntax keyword jetpackProgress Copying
  syntax keyword jetpackProgress Merging
  syntax keyword jetpackComplete Installed
  syntax keyword jetpackComplete Updated
  syntax keyword jetpackComplete Copied
  syntax keyword jetpackComplete Merged
  syntax keyword jetpackSkipped Skipped
  highlight def link jetpackProgress DiffChange
  highlight def link jetpackComplete DiffAdd
  highlight def link jetpackSkipped DiffDelete
endfunction

function s:setbufline(lnum, text, ...)
  call setbufline('JetpackStatus', a:lnum, a:text)
  redraw
endfunction

function s:createbuf()
  silent vsplit +setlocal\ buftype=nofile\ nobuflisted\ noswapfile\ nonumber\ nowrap JetpackStatus
  vertical resize 40
  call s:syntax()
  redraw
endfunction

function s:deletebuf()
  execute 'bdelete ' .. bufnr('JetpackStatus')
  redraw
endfunction

function jetpack#install(...)
  call s:createbuf()
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
    if pkg.branch != 0
      call extend(cmd, ['-b', pkg.branch])
    endif
    call extend(cmd, [pkg.url, pkg.path])
    let job = s:jobstart(cmd, function('<SID>setbufline', [i+3, printf('Installed %s', pkg.name)]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
  call s:deletebuf()
endfunction

function jetpack#update(...)
  call s:createbuf()
  let jobs = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    call s:setbufline(1, printf('Update Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:pkgs)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Updating %s ...', pkg.name))
    if (a:0 > 0 && index(a:000, pkg.name) < 0) || (pkg.frozen || !isdirectory(pkg.path))
      call s:setbufline(i+3, printf('Skipped %s', pkg.name))
      continue
    endif
    let cmd = ['git', '-C', pkg.path, 'pull']
    let job = s:jobstart(cmd, function('<SID>setbufline', [i+3, printf('Updated %s', pkg.name)]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
  call s:deletebuf()
endfunction

function jetpack#bundle()
  let bundle = []
  let unbundle = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    if g:jetpack#optimization >= 1 && !pkg.opt
      call add(bundle, pkg)
    else
      call add(unbundle, pkg)
    endif
  endfor

  call delete(s:optdir, 'rf')
  let destdir = s:optdir .. '/_'

  call s:createbuf()
  for i in range(len(bundle))
    let pkg = bundle[i]
    call s:setbufline(1, printf('Merging Plugins (%d / %d)', i, len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * i / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Merging %s ...', pkg.name))
    let srcdir = pkg.path .. '/' .. pkg.subdir
    let srcfiles = filter(s:files(srcdir), {_, f -> !s:ignorable(substitute(f, srcdir, '', ''))})
    let destfiles = map(copy(srcfiles), {_, f -> substitute(f, srcdir, destdir, '')})

    if g:jetpack#optimization == 1
      let ignore = v:false
      for destfile in destfiles
        if filereadable(destfile)
          let ignore = v:true
          break
        endif
      endfor
      if ignore
        call add(unbundle, pkg)
        continue
      endif
    endif

    for i in range(0, len(srcfiles) - 1)
      let srcfile = srcfiles[i]
      let destfile = destfiles[i]
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      call s:copy(srcfile, destfile)
    endfor
    call s:setbufline(i+3, printf('Merged %s ...', pkg.name))
  endfor

  for i in range(len(unbundle))
    let pkg = unbundle[i]
    call s:setbufline(1, printf('Copy Plugins (%d / %d)', i+len(bundle), len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * (i+len(bundle)) / len(s:pkgs) * 100))
    call s:setbufline(i+len(bundle)+3, printf('Copying %s ...', pkg.name))
    let srcdir = pkg.path .. '/' .. pkg.subdir
    let destdir = s:optdir .. '/' .. pkg.name
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      call s:copy(srcfile, destfile)
    endfor
    call s:setbufline(i+len(bundle)+3, printf('Copied %s ...', pkg.name))
  endfor
  call s:deletebuf()
endfunction

function jetpack#postupdate()
  silent! packadd _
  for pkg in s:pkgs
    let pwd = getcwd()
    if isdirectory(s:optdir .. '/' .. pkg.name)
      execute printf('cd %s/%s', s:optdir, pkg.name)
    else
      execute printf('cd %s/_', s:optdir)
    endif
    execute 'silent! packadd ' .. pkg.name
    if type(pkg.hook) == v:t_func
      call pkg.hook()
    endif
    if type(pkg.hook) == v:t_string
      if pkg.hook =~ '^:'
        execute pkg.hook
      else
        call system(pkg.hook)
      endif
    endif
    execute printf('cd %s', pwd)
  endfor
  silent! helptags ALL
endfunction

function jetpack#sync()
  echomsg 'Installing plugins ...'
  call jetpack#install()
  echomsg 'Updating plugins ...'
  call jetpack#update()
  echomsg 'Bundling plugins ...'
  call jetpack#bundle()
  echomsg 'Running the post-update hooks ...'
  call jetpack#postupdate()
  echomsg 'Complete'
endfunction
command! JetpackSync call jetpack#sync()

function jetpack#add(plugin, ...)
  let opts = a:0 > 0 ? a:1 : {}
  let name = get(opts, 'as', fnamemodify(a:plugin, ':t'))
  let path = get(opts, 'dir', s:srcdir .. '/' .. name)
  let pkg  = {
        \  'url': 'https://github.com/' .. a:plugin,
        \  'branch': get(opts, 'branch', get(opts, 'tag')),
        \  'hook': get(opts, 'do'),
        \  'subdir': get(opts, 'rtp', '.'),
        \  'name': name,
        \  'frozen': get(opts, 'frozen'),
        \  'path': path,
        \  'opt': get(opts, 'opt')
        \ }
  for it in flatten([get(opts, 'for', [])])
    let pkg.opt = 1
    execute printf('autocmd FileType %s silent! packadd %s', it, name)
  endfor
  for it in flatten([get(opts, 'on', [])])
    let pkg.opt = 1
    if it =~ '^<Plug>'
      execute printf("nnoremap %s :execute '".'silent! packadd %s \| call feedkeys("\%s")'."'<CR>", it, name, it)
    elseif index(s:events, it) >= 0
      execute printf('autocmd %s * silent! packadd %s', it, name)
    else
      execute printf('autocmd CmdUndefined %s silent! packadd %s', substitute(it, '^:', '', ''), name)
    endif
  endfor
  if pkg.opt
    execute printf('autocmd SourcePre %s/%s/**/* let s:loaded["%s"]=1', s:optdir, name, name)
  else
    execute 'silent! packadd! ' .. name
  endif
  call add(s:pkgs, pkg)
endfunction

function jetpack#begin(...)
  syntax off
  filetype off
  command! -nargs=+ Jetpack call jetpack#add(<args>)
  let s:home = a:0 != 0 ? a:1 : s:home
  let s:optdir = s:home .. '/pack/jetpack/opt'
  let s:srcdir = s:home .. '/pack/jetpack/src'
  let s:pkgs = []
  execute 'set packpath^=' .. s:home
endfunction

function jetpack#end()
  syntax enable
  filetype plugin indent on
  delcommand Jetpack
  silent! packadd! _
endfunction

function jetpack#tap(name)
  if get(s:loaded, a:name, 0)
    return 1
  endif
  if isdirectory(s:srcdir .. '/' .. a:name)
    for pkg in s:pkgs
      if pkg.name == a:name
        if !pkg.opt
          return 1
        endif
        break
      endif
    endfor
  endif
  return 0
endfunction
