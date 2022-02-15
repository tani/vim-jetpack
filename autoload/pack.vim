"=============== JETPACK.vim =================
"      The lightnig-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:pack#optimization = 1

let s:home = expand(has('nvim') ? '~/.local/share/nvim/site' : '~/.vim')
let s:packdir = s:home .. '/pack/jetpack'

let s:pkgs = []
let s:plugs = []
let s:ignores = [
  \ "**/.*",
  \ "**/.*/**/*",
  \ "**/t/**/*",
  \ "**/test/**/*",
  \ "**/VimFlavor*",
  \ "**/Flavorfile*",
  \ "**/README*",
  \ "**/Rakefile*",
  \ "**/Gemfile*",
  \ "**/Makefile*",
  \ "**/LICENSE*",
  \ "**/LICENCE*",
  \ "**/CONTRIBUTING*",
  \ "**/CHANGELOG*",
  \ "**/NEWS*",
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

fu s:files(path)
  let files = []
  for item in glob(a:path .. '/**/*', '', 1)
    if glob(item .. '/') == ''
      call add(files, item)
    endif
  endfor
  retu files
endfunction

fu s:ignorable(filename)
  for ignore in s:ignores
    if a:filename =~ glob2regpat(ignore)
      retu 1
    endif
  endfor
  retu 0
endfunction

fu s:mergable(pkgs, pkg)
  echomsg printf('Checking %s ...', pkg.name)
  let path = []
  for pkg in a:pkgs
    call add(path, pkg.path)
  endfor
  let path = join(path, ',')
  for abspath in s:files(a:pkg.path)
    let relpath = substitute(abspath, a:pkg.path, '', '')
    if !s:ignorable(relpath) && globpath(path, '**/' .. relpath) != ''
      retu 0
    endif
  endfor
  retu 1
endfunction

fu s:wait(jobs)
  if has('nvim')
    call jobwait(a:jobs)
  else
    let running = 1
    while running 
      let running = 0
      for job in a:jobs
        if job_status(job) == 'run'
          let running = 1
        endif
      endfor
      sleep 1
    endwhile
  endif
endfunction

fu s:jobstart(cmd)
  if has('nvim')
    retu jobstart(a:cmd)
  else
    retu job_start(a:cmd)
  endif
endfu

fu pack#install(...)
  let jobs = []
  for pkg in s:pkgs
    if a:0 > 0 && index(a:000, pkg.name) < 0
      continue
    endif
    if glob(pkg.path .. '/') == ''
      echomsg printf('Cloning %s ...', pkg.name)
      let cmd = ['git', 'clone']
      if pkg.branch
        call extend(cmd, ['-b', pkg.branch])
      endif
      call extend(cmd, [pkg.url, pkg.path])
      call add(jobs, s:jobstart(cmd))
    endif
  endfor
  call s:wait(jobs)
endfunction

fu pack#update(...)
  let jobs = []
  for pkg in s:pkgs
    if a:0 > 0 && index(a:000, pkg.name) < 0
      continue
    endif
    if !pkg.frozen && glob(pkg.path .. '/') != ''
      echomsg printf('Updating %s ...', pkg.name)
      call add(jobs, s:jobstart(['git', '-C', pkg.path, 'pull']))
    endif
  endfor
  call s:wait(jobs)
endfunction

fu pack#bundle()
  let bundle = []
  let unbundle = []
  for pkg in s:pkgs
    if g:pack#optimization >= 1
         \ && pkg.packtype == 'start'
         \ && (g:pack#optimization || s:mergable(bundle, pkg))
      call add(bundle, pkg)
    else
      call add(unbundle, pkg)
    endif
  endfor
  call delete(s:packdir .. '/opt', 'rf')
  call delete(s:packdir .. '/start', 'rf')
  let destdir = s:packdir .. '/start/_'
  for pkg in bundle
    let srcdir = pkg.path .. '/' .. pkg.subdir
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '') 
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      call writefile(blob, destfile, 'b')
    endfor
  endfor
  for pkg in unbundle
    let srcdir = pkg.path .. '/' .. pkg.subdir
    let destdir = s:packdir .. '/' .. pkg.packtype .. '/' .. pkg.name
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      call writefile(blob, destfile, 'b')
    endfor
  endfor
endfunction

fu pack#postupdate()
  packloadall 
  for pkg in s:pkgs
    if type(pkg.hook) == v:t_func
      call pkg.hook()
    endif
    if type(pkg.hook) == v:t_string
      if pkg.hook =~ '^:'
        call system(pkg.hook)
      else
        execute pkg.hook
      endif
    endif
  endfor
  packloadall | silent! helptags ALL
endfunction

fu pack#sync()
  echomsg 'Installing plugins ...'
  call pack#install()
  echomsg 'Updating plugins ...'
  call pack#update()
  echomsg 'Bundling plugins ...'
  call pack#bundle()
  echomsg 'Running the post-update hooks ...'
  call pack#postupdate()
  echomsg 'Complete'
endfunction

fu pack#add(plugin, ...)
  let opts = {}
  if a:0 > 0
    call extend(opts, a:1)
  endif
  let name = fnamemodify(a:plugin, ':t')
  let path = s:packdir .. '/src/' .. name
  let pkg  = {
        \  'url': 'https://github.com/' .. a:plugin,
        \  'branch': get(opts, 'branch', get(opts, 'tag')),
        \  'hook': get(opts, 'do'),
        \  'subdir': get(opts, 'rtp', '.'),
        \  'name': get(opts, 'as', name),
        \  'frozen': get(opts, 'frozen'),
        \  'path': get(opts, 'dir', path),
        \  'packtype': get(opts, 'opt') ? 'opt' : 'start',
        \ }
  let ft = get(opts, 'for', [])
  let ft = type(ft) == v:t_string ? split(ft, ',') : ft
  let ft = ft == [''] ? [] : ft
  for it in ft
    let pkg.packtype = 'opt'
    execute printf('autocmd FileType %s silent! packadd %s', it, name)
  endfor
  let cmd = get(opts, 'on', [])
  let cmd = type(cmd) == v:t_string ? split(cmd, ',') : cmd
  let cmd = cmd == [''] ? [] : cmd
  for it in cmd
    let pkg.packtype = 'opt'
    if it =~ '^<Plug>'
      execute printf("nnoremap %s :execute '".'packadd %s \| call feedkeys("\%s")'."'<CR>", it, name, it)
    elseif index(s:events, it) >= 0
      execute printf('autocmd %s silent! packadd %s', it, name)
    else
      execute printf('autocmd CmdUndefined %s silent! packadd %s', it, name)
    endif
  endfor
  call add(s:pkgs, pkg)
endfunction

fu pack#begin(...)
  if a:0 != 0
    let s:home = a:1
    let s:packdir = s:home .. '/pack/jetpack'
    execute 'set packpath^=' .. s:home
  endif
  command! -nargs=+ Pack call pack#add(<args>)
endfunction

fu pack#end()
  delcommand Pack
endfunction

command! -nargs=* PackInstall call pack#install(<q-args>)
command! -nargs=* PackUpdate call pack#update(<q-args>)
command! PackBundle call pack#bundle()
command! PackPostUpdate call pack#postupdate()
command! PackSync call pack#sync()
