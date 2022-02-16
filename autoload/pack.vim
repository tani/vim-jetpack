"=============== JETPACK.vim =================
"      The lightnig-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:pack#optimization = 1
let g:pack#njobs = 8

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

function s:mergable(pkgs, pkg)
  let path = join(mapnew(a:pkgs, {_, v -> v.path}), ',')
  for replpath in map(s:files(a:pkg.path), {_, v -> substitute(v , a:pkg.path, '', '')})
    if !s:ignorable(relpath) && globpath(path, '**/' .. relpath) != ''
      return 0
    endif
  endfor
  return 1
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
  if has('nvim')
    return jobstart(a:cmd, { 'on_exit': a:cb })
  endif
  return job_start(a:cmd, { 'exit_cb': a:cb })
endfunction

function s:syntax()
  syntax clear
  syntax keyword packProgress Installing
  syntax keyword packProgress Updating
  syntax keyword packProgress Checking
  syntax keyword packProgress Copying
  syntax keyword packComplete Installed
  syntax keyword packComplete Updated
  syntax keyword packComplete Checked
  syntax keyword packComplete Copied
  syntax keyword packSkipped Skipped
  highlight def link packProgress DiffChange
  highlight def link packComplete DiffAdd
  highlight def link packSkipped DiffDelete
endfunction

function s:setbufline(lnum, text, ...)
  call setbufline('PackStatus', a:lnum, a:text)
  redraw
endfunction

function s:createbuf()
  silent vsplit +setlocal\ buftype=nofile\ nobuflisted\ noswapfile\ nonumber\ nowrap PackStatus
  vertical resize 40
  call s:syntax()
  redraw
endfunction

function s:deletebuf()
  execute 'bdelete ' .. bufnr('PackStatus')
  redraw
endfunction

function pack#install(...)
  call s:createbuf()
  let jobs = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    call s:setbufline(1, printf('Install Plugins (%d / %d)', (len(jobs) - s:jobcount(jobs)), len(s:pkgs)))
    call s:setbufline(2, s:progressbar((0.0 + len(jobs) - s:jobcount(jobs)) / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Installing %s ...', pkg.name))
    if (a:0 > 0 && index(a:000, pkg.name) < 0) || isdirectory(pkg.path)
      call s:setbufline('PackInstall', i+3, printf('Skipped %s', pkg.name))
      continue
    endif
    let cmd = ['git', 'clone', '--depth', '1']
    if pkg.branch
      call extend(cmd, ['-b', pkg.branch])
    endif
    call extend(cmd, [pkg.url, pkg.path])
    let job = s:jobstart(cmd, function('<SID>setbufline', [i+3, printf('Installed %s', pkg.name)]))
    call add(jobs, job)
    call s:jobwait(jobs, g:pack#njobs)
  endfor
  call s:jobwait(jobs, 0)
  call s:deletebuf()
endfunction

function pack#update(...)
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
    call s:jobwait(jobs, g:pack#njobs)
  endfor
  call s:jobwait(jobs, 0)
  call s:deletebuf()
endfunction

function pack#bundle()
  call s:createbuf()
  let bundle = []
  let unbundle = []
  for i in range(len(s:pkgs))
    let pkg = s:pkgs[i]
    call s:setbufline(1, printf('Check Plugins (%d / %d)', i, len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * i / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Checking %s ...', pkg.name))
    if g:pack#optimization >= 1
         \ && !pkg.opt
         \ && (g:pack#optimization || s:mergable(bundle, pkg))
      call add(bundle, pkg)
    else
      call add(unbundle, pkg)
    endif
    call s:setbufline(i+3, printf('Checked %s', pkg.name))
  endfor
  call delete(s:packdir .. '/opt', 'rf')
  let destdir = s:packdir .. '/opt/_'
  call s:deletebuf()

  call s:createbuf()
  for i in range(len(bundle))
    let pkg = bundle[i]
    call s:setbufline(1, printf('Copy Plugins (%d / %d)', i, len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * i / len(s:pkgs) * 100))
    call s:setbufline(i+3, printf('Coping %s ...', pkg.name))
    let srcdir = pkg.path .. '/' .. pkg.subdir
    for srcfile in s:files(srcdir)
      if !s:ignorable(substitute(srcfile, srcdir, '', ''))
        let destfile = substitute(srcfile, srcdir, destdir, '') 
        call mkdir(fnamemodify(destfile, ':p:h'), 'p')
        let blob = readfile(srcfile, 'b')
        call writefile(blob, destfile, 'b')
      endif
    endfor
    call s:setbufline(i+3, printf('Copied %s ...', pkg.name))
  endfor

  for i in unbundle
    let pkg = unbundle[i]
    call s:setbufline(1, printf('Copy Plugins (%d / %d)', i+len(bundle), len(s:pkgs)))
    call s:setbufline(2, s:progressbar(1.0 * (i+len(bundle)) / len(s:pkgs) * 100))
    call s:setbufline(i+len(bundle)+3, printf('Copying %s ...', pkg.name))
    let srcdir = pkg.path .. '/' .. pkg.subdir
    let destdir = s:packdir .. '/opt/' .. pkg.name
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      call writefile(blob, destfile, 'b')
    endfor
    call s:setbufline(i+len(bundle)+3, printf('Copyied %s ...', pkg.name))
  endfor
  call s:deletebuf()
endfunction

function pack#postupdate()
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

function pack#sync()
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

function pack#add(plugin, ...)
  let opts = a:0 > 0 ? a:1 : {}
  let name = get(opts, 'as', fnamemodify(a:plugin, ':t'))
  let path = get(opts, 'dir', s:packdir .. '/src/' .. name)
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
      execute printf("nnoremap %s :execute '".'packadd %s \| call feedkeys("\%s")'."'<CR>", it, name, it)
    elseif index(s:events, it) >= 0
      execute printf('autocmd %s silent! packadd %s', it, name)
    else
      execute printf('autocmd CmdUndefined %s silent! packadd %s', it, name)
    endif
  endfor
  call add(s:pkgs, pkg)
  if !pkg.opt && isdirectory(s:packdir .. '/opt/' .. name)
    execute 'silent! packadd! ' .. name
  endif
endfunction

function pack#begin(...)
  let s:home = a:0 != 0 ? a:1 : s:home
  let s:packdir = s:home .. '/pack/jetpack'
  execute 'set packpath^=' .. s:home
  command! -nargs=+ Pack call pack#add(<args>)
  filetype off
endfunction

function pack#end()
  delcommand Pack
  silent! packadd! _
  filetype plugin indent on
endfunction

command! PackSync call pack#sync()
