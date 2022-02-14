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

fu s:files(path)
  let files = []
  for item in glob(a:path .. '/**/*', '', 1)
    if glob(item .. '/') == ''
      cal add(files, item)
    en
  endfo
  retu files
endf

fu s:ignorable(filename)
  for ignore in s:ignores
    if a:filename =~ glob2regpat(ignore)
      retu 1
    en
  endfo
  retu 0
endf

fu s:mergable(pkgs, pkg)
  let path = []
  for pkg in a:pkgs
    call add(path, pkg.path)
  endfo
  let path = join(path, ',')
  for abspath in s:files(a:pkg.path)
    let relpath = substitute(abspath, a:pkg.path, '', '')
    if !s:ignorable(relpath) && globpath(path, '**/' .. relpath) != ''
      retu 0
    en
  endfo
  retu 1
endf

fu s:wait(jobs)
  if has('nvim')
    call jobwait(a:jobs)
  el
    let running = 1
    wh running 
      let running = 0
      for job in a:jobs
        if job_status(job) == 'run'
          let running = 1
        en
      endfo
      sl 1
    endw
  en
endf

fu s:jobstart(cmd)
  if has('nvim')
    return jobstart(a:cmd)
  el
    return job_start(a:cmd)
  endif
endfu

fu pack#install()
  let jobs = []
  for pkg in s:pkgs
    if glob(pkg.path .. '/') == ''
      let cmd = ['git', 'clone']
      if pkg.branch
        cal extend(cmd, ['-b', pkg.branch])
      en
      cal extend(cmd, [pkg.url, pkg.path])
      cal add(jobs, s:jobstart(cmd))
    en
  endfo
  cal s:wait(jobs)
endf

fu pack#update()
  let jobs = []
  for pkg in s:pkgs
    if !pkg.frozen && glob(pkg.path .. '/') != ''
      cal add(jobs, s:jobstart(['git', '-C', pkg.path, 'pull']))
    en
  endfo
  cal s:wait(jobs)
endf

fu pack#bundle()
  let bundle = []
  let unbundle = []
  for pkg in s:pkgs
    if g:pack#optimization >= 1
         \ && pkg.packtype == 'start'
         \ && (g:pack#optimization || s:mergable(bundle, pkg))
      cal add(bundle, pkg)
    el
      cal add(unbundle, pkg)
    en
  endfo
  cal delete(s:packdir .. '/opt', 'rf')
  cal delete(s:packdir .. '/start', 'rf')
  let destdir = s:packdir .. '/start/_'
  for pkg in bundle
    let srcdir = pkg.path .. '/' .. pkg.subdir
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '') 
      cal mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      cal writefile(blob, destfile, 'b')
    endfo
  endfo
  for pkg in unbundle
    let srcdir = pkg.path .. '/' .. pkg.subdir
    let destdir = s:packdir .. '/' .. pkg.packtype .. '/' .. pkg.name
    for srcfile in s:files(srcdir)
      let destfile = substitute(srcfile, srcdir, destdir, '')
      cal mkdir(fnamemodify(destfile, ':p:h'), 'p')
      let blob = readfile(srcfile, 'b')
      cal writefile(blob, destfile, 'b')
    endfo
  endfo
endf

fu pack#helptags()
  packl | sil! helpt ALL
endf

fu pack#hook()
  packl 
  for pkg in s:pkgs
    if type(pkg.hook) == v:t_func
      cal pkg.hook()
    el
      if pkg.hook =~ '^:'
        call system(pkg.hook)
      el
        exe pkg.hook
      en
    en
  endfo
endf

fu pack#sync()
  echom 'Installing plugins ...'
  cal pack#install()
  echom 'Updating plugins ...'
  cal pack#update()
  echom 'Bundling plugins ...'
  cal pack#bundle()
  echom 'Running hooks ...'
  cal pack#hook()
  echom 'Generating helptags ...'
  cal pack#helptags()
  echom 'Complete'
endf

fu pack#add(plugin, ...)
  let opts = {
        \ 'as': fnamemodify(a:plugin, ':t'),
        \ 'opt': 0,
        \ 'for': [],
        \ 'branch': 0,
        \ 'tag': 0,
        \ 'do': '',
        \ 'rtp': '.',
        \ 'on': [],
        \ 'frozen': 0,
        \ }
  if a:0 > 0
    cal extend(opts, a:1)
  en
  let pkg  = {
        \  'url': 'https://github.com/' .. a:plugin,
        \  'branch': get(opts, 'branch', get(opts, 'tag')),
        \  'hook': get(opts, 'do'),
        \  'subdir': get(opts, 'rtp'),
        \  'name': get(opts, 'as'),
        \  'command': get(opts, 'on'),
        \  'filetype': get(opts, 'for'),
        \  'frozen': get(opts, 'frozen'),
        \  'path': get(opts, 'dir', s:packdir .. '/src/' .. get(opts, 'as')),
        \  'packtype': get(opts, 'opt') ? 'opt' : 'start',
        \ }
  let ft = get(pkg, 'filetype')
  if type(ft) == v:t_list && ft != []
    let pkg.packtype = 'opt'
    exe 'au FileType '  .. join(ft, ',') .. ' sil! pa ' .. pkg.name
  en
  if type(ft) == v:t_string && ft != ''
    let pkg.packtype = 'opt'
    exe 'au FileType '  .. ft .. ' sil! pa ' .. pkg.name
  en
  let cmd = get(pkg, 'command')
  if type(cmd) == v:t_list && cmd != []
    let pkg.packtype = 'opt'
    exe 'au CmdUndefined '  .. join(cmd, ',') .. ' sil! pa ' .. pkg.name
  en
  if type(cmd) == v:t_string && cmd != ''
    let pkg.packtype = 'opt'
    exe 'au CmdUndefined '  .. cmd .. ' sil! pa ' .. pkg.name
  en
  cal add(s:pkgs, pkg)
endf

fu pack#begin(...)
  if a:0 != 0
    let s:home = a:1
    let s:packdir = s:home .. '/pack/jetpack'
    exe 'se pp^=' .. s:home
  en
  com! -nargs=+ Pack cal pack#add(<args>)
endf

fu pack#end()
  delc Pack
endf

com! PackSync cal pack#sync()
