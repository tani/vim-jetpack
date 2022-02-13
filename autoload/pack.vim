"=============== JETPACK.vim =================
"      The lightnig-fast plugin manager
"     Copyrigh (c) 2022 TANGUCHI Masaya.
"          All Rights Reserved.
"=============================================

let g:pack#optimization = 1

if has('nvim')
  let s:homedir = expand('~/.local/share/nvim/site')
else
  let s:homedir = expand('~/.vim')
endif

let s:packages = []
let s:ignores = [
  \ "**/.*",
  \ "**/.*/**/*",
  \ "**/t/**/*",
  \ "**/test/**/*",
  \ "**/VimFlavor*",
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

function s:packdir()
  return s:homedir .. '/pack/jetpack'
endfunction

function s:allfiles(path)
  let files = []
  for item in glob(a:path .. '/**/*', '', 1)
    if glob(item .. '/') == ''
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

function s:mergable(packages, package)
  for package in a:packages
    for abspath1 in s:allfiles(package.path)
      let relpath1 = substitute(abspath1, package.path, '', '')
      if !s:ignorable(relpath1)
        for abspath2 in s:allfiles(a:package.path)
          let relpath2 = substitute(abspath2, a:package.path, '', '')
          if (relpath1 == relpath2)
            return 0
          endif
        endfor
      endif
    endfor
  endfor
  return 1
endfunction

function s:wait(jobs)
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
endfunction

function pack#install()
  let jobs = []
  for package in s:packages
    if glob(package.path .. '/') == ''
      if package.branch != ''
        call add(jobs, job_start(['git', 'clone', '-b', package.branch, package.url, package.path]))
      else
        call add(jobs, job_start(['git', 'clone', package.url, package.path]))
      endif
    endif
  endfor
  call s:wait(jobs)
endfunction

function pack#update()
  let jobs = []
  for package in s:packages
    if glob(package.path .. '/') != ''
      call add(jobs, job_start(['git', '-C', package.path, 'pull']))
    endif
  endfor
  call s:wait(jobs)
endfunction

function pack#bundle()
  let bundle = []
  let unbundle = []
  for package in s:packages
    if (g:pack#optimization >= 1 && package.packtype == 'start' && (g:pack#optimization == 2 || s:mergable(bundle, package)))
      call add(bundle, package)
    else
      call add(unbundle, package)
    endif
  endfor
  call delete(s:packdir() .. '/opt', 'rf')
  call delete(s:packdir() .. '/start', 'rf')
  let destdir = s:packdir() .. '/start/_'
  for package in bundle
    let srcdir = package.path .. '/' .. package.dir
    for srcfile in s:allfiles(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '') 
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      call writefile(blob, destfile, 'b')
    endfor
  endfor
  for package in unbundle
    let srcdir = package.path .. '/' .. package.dir
    let destdir = s:packdir() .. '/' .. package.packtype .. '/' .. package.name
    for srcfile in s:allfiles(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      call mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      call writefile(blob, destfile, 'b')
    endfor
  endfor
endfunction

function pack#hook()
  packloadall
  for package in s:packages
    if type(package.hook) == v:t_func
      call package.hook()
    else
      execute package.hook
    endif
  endfor
endfunction

function pack#sync()
  echomsg 'Installing plugins ...'
  call pack#install()
  echomsg 'Updating plugins ...'
  call pack#update()
  echomsg 'Switching plugins ...'
  call pack#bundle()
  echomsg "Running hooks ..."
  call pack#hook()
  echomsg "Generating helptags ..."
  helptags ALL
  echomsg 'Complete'
endfunction

function pack#clean()
  delete(s:packdir, 'rf')
endfunction

function pack#add(plugin, ...)
  let options = {
        \ 'name': fnamemodify(a:plugin, ':t'),
        \ 'opt': 0,
        \ 'for': [],
        \ 'do': '',
        \ 'branch': '',
        \ 'rtp': '.',
        \ }
  if a:0 > 0
    call extend(options, a:1)
  endif
  let package  = {}
  let package.url = 'https://github.com/' .. a:plugin
  let package.branch = get(options, 'branch')
  let package.hook = get(options, 'do')
  let package.subdir = get(options, 'rtp')
  let package.name = get(options, 'as')
  let package.path = s:packdir() .. '/src/' .. package.name
  if get(options, 'opt')
    let package.packtype = 'opt'
  else
    let package.packtype = 'start'
  endif
  let ft = get(options, 'for') 
  if ft != [] && type(ft) == v:t_list
    let package.packtype = 'opt'
    execute 'autocmd FileType '  .. join(ft, ',') .. ' silent! packadd ' .. package.name
  endif
  if ft != '' && type(ft) == v:t_string
    let package.packtype = 'opt'
    execute 'autocmd FileType '  .. ft .. ' silent! packadd ' .. package.name
  endif
  call add(s:packages, package)
endfunction

function pack#begin(...)
  if a:0 != 0
    let s:homedir = a:1
  endif
  execute 'set packpath^=' .. s:homedir
  command! -nargs=+ Pack :call pack#add(<args>)
endfunction

function pack#end()
  delcommand Pack
endfunction

command! PackSync :call pack#sync()
