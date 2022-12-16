"=================================== Jetpack ==================================
"Copyright (c) 2022 TANIGUCHI Masaya
"
"Permission is hereby granted, free of charge, to any person obtaining a copy
"of this software and associated documentation files (the "Software"), to deal
"in the Software without restriction, including without limitation the rights
"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"copies of the Software, and to permit persons to whom the Software is
"furnished to do so, subject to the following conditions:
"
"The above copyright notice and this permission notice shall be included in all
"copies or substantial portions of the Software.
"
"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
"SOFTWARE.
"==============================================================================

if exists('g:loaded_jetpack')
  finish
endif
let g:loaded_jetpack = 1

function! s:execute(code) abort
  call execute(a:code->substitute('\n\s*\\', ' ', 'g')->split("\n"))
endfunction

function! s:packadd(pkg_name, bang='') abort
  if isdirectory(s:optdir . '/'. a:pkg_name)
    execute 'packadd'.a:bang a:pkg_name
  endif
endfunction

function! s:autocmd_add(autocmds) abort
  call autocmd_add(a:autocmds)
endfunction

if !exists('?autocmd_add')
  function! s:autocmd_add(autocmds) abort
    for a in a:autocmds
      call extend(a, {'group': '', 'pattern': '*', 'cmd': ':', 'once': v:false}, 'keep')
      let once = a.once ? '++once' : ''
      execute 'autocmd' a.group a.event a.pattern once a.cmd
    endfor
  endfunction
endif

let g:jetpack_njobs = get(g:, 'jetpack_njobs', 8)

let g:jetpack_ignore_patterns =
  \ get(g:, 'jetpack_ignore_patterns', [
  \   '[\/]doc[\/]tags*',
  \   '[\/]test[\/]*',
  \   '[\/][.ABCDEFGHIJKLMNOPQRSTUVWXYZ]*'
  \ ])

let g:jetpack_download_method =
  \ get(g:, 'jetpack_download_method', 'git')
  " curl: Use CURL to download
  " wget: Use Wget to download

let g:jetpack_copy_method =
  \ get(g:, 'jetpack_copy_method', 'system')
  " sytem    : cp/ xcopy
  " copy     : readfile and writefile
  " symlink  : fs_symlink (nvim only)
  " hardlink : fs_link (nvim only)

let s:cmds = {}
let s:maps = {}

let s:declared_packages = get(s:, 'packages', {})

let s:status = {
\   'pending': 'pending',
\   'skipped': 'skipped',
\   'installed': 'installed',
\   'installing': 'installing',
\   'updated': 'updated',
\   'updating': 'updating',
\   'switched': 'switched',
\   'merged': 'merged',
\   'copied': 'copied'
\ }

function! s:check_ignorable(filename) abort
  return filter(copy(g:jetpack_ignore_patterns), { _, val -> a:filename =~# glob2regpat(val) }) != []
endfunction

function! s:list_files(path) abort
  let files = readdir(a:path, { entry -> filereadable(a:path . '/' . entry) })
  let files = map(files, { _, entry -> a:path . '/' . entry })
  let dirs = readdir(a:path, { entry -> isdirectory(a:path . '/' . entry) })
  let dirs = map(dirs, { _, entry -> a:path . '/' . entry })
  for dir in dirs
    let files += s:list_files(dir)
  endfor
  return files
endfunction

function! jetpack#parse_toml(lines) abort
  let plugins = {}
  let repo = ''
  let key = ''
  let value = ''
  let plugin = {}
  let multiline = ''
  for line in a:lines
    if !empty(multiline)
      if multiline == ']'
        let plugin[key] .= line
        if trim(line) =~ multiline
          let plugin[key] = eval(plugin[key])
          let multiline = ''
        endif
      else
        if trim(line) =~ multiline
          let plugin[key] .= substitute(line, multiline, '', '')
          let multiline = ''
        else
          let plugin[key] .= line . "\n"
        endif
      endif
      continue
    endif
    if trim(line) =~ '^#'
      continue
    endif
    if trim(line) =~ '^$'
      continue
    endif
    if trim(line) =~ '^\[\[plugins\]\]$'
      let plugins[repo] = deepcopy(plugin)
      let plugin = {}
      continue
    endif
    if trim(line) =~ '^repo\s*=\s*'
      let repo = eval(substitute(trim(line), 'repo\s*=\s*', '', ''))
      continue
    endif
    if trim(line) =~ '^\w\+\s*=\s*'
      let key = substitute(trim(line), '^\(\w\+\)\s*=\s*.*', '\1', '')
      let raw = substitute(trim(line), '^\w\+\s*=\s*', '', '')
      if trim(raw) =~ '^""".*"""$'
        let plugin[key] = substitute(trim(raw), '"""', '', 'g')
      elseif trim(raw) =~ "^'''.*'''$"
        let plugin[key] = substitute(trim(raw), "'''", '', 'g')
      elseif trim(raw) =~ '^"""' || trim(raw) =~ "^'''"
        let multiline = trim(raw) =~ '^"""' ? '"""' : "'''"
        let plugin[key] = substitute(trim(raw), '^...', '', '') 
      elseif trim(raw) =~ '^\[.*\]$'
        let plugin[key] = eval(raw)
      elseif trim(raw) =~ '^\['
        let multiline = ']'
        let plugin[key] = trim(raw)
      else
        if trim(raw) =~ 'true\|false'
          let value = eval('v:'..raw)
        else
          let value = eval(raw)
        endif
        let plugin[key] = value
      endif
    endif
  endfor
  let plugins[repo] = plugin
  unlet plugins['']
  return plugins
endfunction

function! s:make_progressbar(n) abort
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

" Original: https://github.com/lambdalisue/vital-Whisky/blob/90c71/autoload/vital/__vital__/System/Job/Vim.vim#L46
"  License: https://github.com/lambdalisue/vital-Whisky/blob/90c71/LICENSE
function! s:nvim_exit_cb(buf, cb, job, ...) abort
  let ch = job_getchannel(a:job)
  while ch_status(ch) ==# 'open' | sleep 1ms | endwhile
  while ch_status(ch) ==# 'buffered' | sleep 1ms | endwhile
  call a:cb(join(a:buf, "\n"))
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
  function! s:jobstart(cmd, cb) abort
    let buf = []
    return job_start(a:cmd, {
    \   'out_mode': 'raw',
    \   'out_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'err_mode': 'raw',
    \   'err_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'exit_cb': function('s:nvim_exit_cb', [buf, a:cb])
    \ })
  endfunction
endif

function! s:copy_dir(from, to) abort
  call mkdir(a:to, 'p')
  if g:jetpack_copy_method !=# 'system'
    for src in s:list_files(a:from)
      if src =~# '[\/]tags.*$' " ignore tags
        continue
      endif
      let dest = substitute(src, '\V' . escape(a:from, '\'), escape(a:to, '\'), '')
      call mkdir(fnamemodify(dest, ':p:h'), 'p')
      if g:jetpack_copy_method ==# 'copy'
        call writefile(readfile(src, 'b'), dest, 'b')
        let perm = split(getfperm(src), '\zs')
        let perm[0] = 'r' | let perm[3] = 'r' | let perm[6] = 'r'
        let perm[1] = 'w' | let perm[4] = 'w' | let perm[7] = 'w'
        call setfperm(dest, join(perm, ''))
      elseif g:jetpack_copy_method ==# 'hardlink'
        call v:lua.vim.loop.fs_link(src, dest)
      elseif g:jetpack_copy_method ==# 'symlink'
        call v:lua.vim.loop.fs_symlink(src, dest)
      endif
    endfor
  elseif has('unix')
    call system(printf('cp -R %s/. %s', a:from, a:to))
  elseif has('win32')
    call system(printf('xcopy %s %s /E /Y', expand(a:from), expand(a:to)))
  endif
endfunction

function! s:initialize_buffer() abort
  execute 'silent! bdelete!' bufnr('JetpackStatus')
  40vnew +setlocal\ buftype=nofile\ nobuflisted\ nonumber\ norelativenumber\ signcolumn=no\ noswapfile\ nowrap JetpackStatus
  syntax clear
  syntax match jetpackProgress /^[a-z]*ing/
  syntax match jetpackComplete /^[a-z]*ed/
  syntax keyword jetpackSkipped ^skipped
  highlight def link jetpackProgress DiffChange
  highlight def link jetpackComplete DiffAdd
  highlight def link jetpackSkipped DiffDelete
  redraw
endfunction

function! s:show_progress(title) abort
  let buf = bufnr('JetpackStatus')
  call deletebufline(buf, 1, '$')
  let processed = len(filter(copy(s:declared_packages), { _, val -> val.status[-1] =~# 'ed' }))
  call setbufline(buf, 1, printf('%s (%d / %d)', a:title, processed, len(s:declared_packages)))
  call appendbufline(buf, '$', s:make_progressbar((0.0 + processed) / len(s:declared_packages) * 100))
  for [pkg_name, pkg] in items(s:declared_packages)
    call appendbufline(buf, '$', printf('%s %s', pkg.status[-1], pkg_name))
  endfor
  redraw
endfunction

function! s:show_result() abort
  let buf = bufnr('JetpackStatus')
  call deletebufline(buf, 1, '$')
  call setbufline(buf, 1, 'Result')
  call appendbufline(buf, '$', s:make_progressbar(100))
  for [pkg_name, pkg] in items(s:declared_packages)
    if index(pkg.status, s:status.installed) >= 0
      call appendbufline(buf, '$', printf('installed %s', pkg_name))
    elseif index(pkg.status, s:status.updated) >= 0
      call appendbufline(buf, '$', printf('updated %s', pkg_name))
    else
      call appendbufline(buf, '$', printf('skipped %s', pkg_name))
    endif
    let output = substitute(pkg.output, '\r\n\|\r', '\n', 'g')
    let output = substitute(output, '^From.\{-}\zs\n\s*', '/compare/', '')
    for line in split(output, '\n')
      call appendbufline(buf, '$', printf('  %s', line))
    endfor
  endfor
  redraw
endfunction

function! s:clean_plugins() abort
  if g:jetpack_download_method !=# 'git'
    return
  endif
  for [pkg_name, pkg] in items(s:declared_packages)
    if isdirectory(pkg.path)
      let branch = trim(system(printf('git -C %s rev-parse --abbrev-ref %s', pkg.path, pkg.commit)))
      if v:shell_error
        call delete(pkg.path, 'rf')
        continue
      endif
      if !empty(pkg.branch) && pkg.branch !=# branch
        call delete(pkg.path, 'rf')
        continue
      endif
      if !empty(pkg.tag) && pkg.tag !=# branch
        call delete(pkg.path, 'rf')
        continue
      endif
    endif
  endfor
endfunction

function! s:make_download_cmd(pkg) abort
  if g:jetpack_download_method ==# 'git'
    if isdirectory(a:pkg.path)
      return ['git', '-C', a:pkg.path, 'pull', '--rebase']
    else
      let cmd = ['git', 'clone']
      if a:pkg.commit ==# 'HEAD'
        call extend(cmd, ['--depth', '1', '--recursive'])
      endif
      if !empty(a:pkg.branch)
        call extend(cmd, ['-b', a:pkg.branch])
      endif
      if !empty(a:pkg.tag)
        call extend(cmd, ['-b', a:pkg.tag])
      endif
      call extend(cmd, [a:pkg.url, a:pkg.path])
      return cmd
    endif
  else
    if !empty(a:pkg.tag)
      let label = a:pkg.tag
    elseif !empty(a:pkg.branch)
      let label = a:pkg.branch
    else
      let label = a:pkg.commit
    endif
    if g:jetpack_download_method ==# 'curl'
      let download_cmd = 'curl -fsSL ' .  a:pkg.url . '/archive/' . label . '.tar.gz'
    elseif g:jetpack_download_method ==# 'wget'
      let download_cmd = 'wget -O - ' .  a:pkg.url . '/archive/' . label . '.tar.gz'
    else
      throw 'g:jetpack_download_method: ' . g:jetpack_download_method . ' is not a valid value'
    endif
    let extract_cmd = 'tar -zxf - -C ' . a:pkg.path . ' --strip-components 1'
    call delete(a:pkg.path, 'rf')
    if has('unix')
      return ['sh', '-c', download_cmd . ' | ' . extract_cmd]
    elseif has('win32')
      return ['cmd.exe', '/c' . download_cmd . ' | ' . extract_cmd]
    endif
  endif
endfunction

function! s:download_plugins() abort
  let jobs = []
  for [pkg_name, pkg] in items(s:declared_packages)
    call add(pkg.status, s:status.pending)
  endfor
  for [pkg_name, pkg] in items(s:declared_packages)
    if pkg.local
      continue
    endif
    call s:show_progress('Install Plugins')
    if isdirectory(pkg.path)
      if pkg.frozen
        call add(pkg.status, s:status.skipped)
        continue
      endif
      call add(pkg.status, s:status.updating)
      let status = s:status.updated
    else
      call add(pkg.status, s:status.installing)
      let status = s:status.installed
    endif
    let cmd = s:make_download_cmd(pkg)
    call mkdir(pkg.path, 'p')
    let job = s:jobstart(cmd, function({status, pkg, output -> [
    \   add(pkg.status, status),
    \   execute("let pkg.output = output")
    \ ]}, [status, pkg]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack_njobs)
  endfor
  call s:jobwait(jobs, 0)
endfunction

function! s:switch_plugins() abort
  if g:jetpack_download_method !=# 'git'
    return
  endif
  for [pkg_name, pkg] in items(s:declared_packages)
    call add(pkg.status, s:status.pending)
  endfor
  for [pkg_name, pkg] in items(s:declared_packages)
    call s:show_progress('Switch Plugins')
    if !isdirectory(pkg.path)
      call add(pkg.status, s:status.skipped)
      continue
    else
      call add(pkg.status, s:status.switched)
    endif
    call system(printf('git -C %s checkout %s', pkg.path, pkg.commit))
  endfor
endfunction

function! s:merge_plugins() abort
  for [pkg_name, pkg] in items(s:declared_packages)
    call add(pkg.status, s:status.pending)
  endfor

  let bundle = {}
  let unbundle = {}
  for [pkg_name, pkg] in items(s:declared_packages)
    if pkg.merged
      let bundle[pkg_name] = pkg
    else
      let unbundle[pkg_name] = pkg
    endif
  endfor

  " Delete old directories
  for dir in glob(s:optdir . '/*', '', 1)
    let pkg_name = fnamemodify(dir, ':t')
    let is_jetpack = pkg_name =~? '^vim-jetpack\(\.git\)\?$'

    if has_key(s:declared_packages, pkg_name) && is_jetpack
      continue
    endif

    if !has_key(s:declared_packages, pkg_name)
     \ || s:declared_packages[pkg_name].output !~# 'Already up to date.'
      if is_jetpack && !s:ask('Delete "' . pkg_name . '"?')
        call s:ask("Please add the following snippet: \"Jetpack 'tani/vim-jetpack', {'opt': 1}\"")
      else
        call delete(dir, 'rf')
      endif
    endif
  endfor

  " Merge plugins if possible.
  let merged_files = []
  for [pkg_name, pkg] in items(bundle)
    call s:show_progress('Merge Plugins')
    let srcdir = pkg.path . '/' . pkg.rtp
    let files = map(s:list_files(srcdir), {_, file -> file[len(srcdir):]})
    let files = filter(files, {_, file -> !s:check_ignorable(file)})
    let conflicted = v:false
    for file in files
      for merged_file in merged_files
        let conflicted =
          \ file =~# '\V' . escape(merged_file, '\') ||
          \ merged_file =~# '\V' . escape(file, '\')
        if conflicted
          break
        endif
      endfor
      if conflicted
        break
      endif
    endfor
    if conflicted
      let unbundle[pkg_name] = pkg
      let pkg.merged = v:false
    else
      call extend(merged_files, files)
      call s:copy_dir(srcdir, s:optdir . '/_')
      call add(pkg.status, s:status.merged)
    endif
  endfor

  " Copy plugins.
  for [pkg_name, pkg] in items(unbundle)
    call s:show_progress('Copy Plugins')
    if !empty(pkg.dir) || pkg.local
      call add(pkg.status, s:status.skipped)
    else
      let srcdir = pkg.path . '/' . pkg.rtp
      let destdir = s:optdir . '/' . pkg_name
      call s:copy_dir(srcdir, destdir)
      call add(pkg.status, s:status.copied)
    endif
  endfor
  let s:available_packages = deepcopy(s:declared_packages)
  for pkg in values(s:available_packages) | unlet pkg.do | endfor
  call mkdir(s:optdir, 'p')
  call writefile([json_encode(s:available_packages)], s:optdir . '/available_packages.json')
endfunction

function! s:postupdate_plugins() abort
  call s:packadd('_')
  for [pkg_name, pkg] in items(s:declared_packages)
    if empty(pkg.do) || pkg.output =~# 'Already up to date.'
      continue
    endif
    if pkg.dir !=# ''
      let pwd = chdir(pkg.path)
    else
      call jetpack#load(pkg_name)
      let pwd = chdir(s:optdir . '/' . pkg_name)
    endif
    if type(pkg.do) == v:t_func
      call pkg.do()
    elseif type(pkg.do) == v:t_string
      if pkg.do =~# '^:'
        execute pkg.do
      else
        call system(pkg.do)
      endif
    endif
    call chdir(pwd)
  endfor
  for dir in glob(s:optdir . '/*/doc', '', 1)
    execute 'silent! helptags' dir
  endfor
endfunction

function! jetpack#sync() abort
  call s:initialize_buffer()
  call s:clean_plugins()
  call s:download_plugins()
  call s:switch_plugins()
  call s:merge_plugins()
  call s:show_result()
  call s:postupdate_plugins()
endfunction

" Original: https://github.com/junegunn/vim-plug/blob/e3001/plug.vim#L479-L529
"  License: MIT, https://raw.githubusercontent.com/junegunn/vim-plug/e3001/LICENSE
if has('win32')
  function! s:is_local_plug(repo) abort
    return a:repo =~? '^[a-z]:\|^[%~]'
  endfunction
else
  function! s:is_local_plug(repo) abort
    return a:repo[0] =~# '[/$~]'
  endfunction
endif

" If opt/do/dir/setup/config option is enabled,
" it should be placed isolated directory (not merged).
function! s:is_merged(pkg) abort
  return !a:pkg.opt
        \ && empty(a:pkg.do)
        \ && empty(a:pkg.dir)
        \ && empty(a:pkg.setup)
        \ && empty(a:pkg.config)
endfunction

function! s:gets(pkg, keys, default) abort
  let values = []
  for key in a:keys
    if has_key(a:pkg, key)
      if type(a:pkg[key]) == v:t_list
        call extend(values, a:pkg[key])
      else
        call add(values, a:pkg[key])
      endif
    endif
  endfor
  return empty(values) ? a:default : values
endfunction

function! jetpack#add(plugin, ...) abort
  let opts = a:0 > 0 ? a:1 : {}
  let local = s:is_local_plug(a:plugin)
  let url = local ? expand(a:plugin) : (a:plugin !~# ':' ? 'https://github.com/' : '') . a:plugin
  let path = s:srcdir . '/' .  substitute(url, 'https\?://', '', '')
  let path = local ? expand(a:plugin) : s:gets(opts, ['dir', 'path'], [path])[0]
  let on = s:gets(opts, [
  \ 'on',
  \ 'keys', 'on_map',
  \ 'cmd', 'on_cmd',
  \ 'event', 'on_event'
  \ ], [])
  let filetypes = s:gets(opts, ['for', 'ft', 'on_ft'], [])
  call extend(on, map(filetypes, {_, ft -> 'FileType ' . ft}))
  let name = s:gets(opts, ['as', 'name'], [fnamemodify(a:plugin, ':t')])[0]
  let requires = s:gets(opts, ['requires', 'depends'], [])
  call map(requires, { _, r -> r =~# '/' ? substitute(r, '.*/', '', '') : r })
  let pkg  = {
  \   'url': url,
  \   'local': local,
  \   'branch': get(opts, 'branch', ''),
  \   'tag': get(opts, 'tag', ''),
  \   'commit': get(opts, 'commit', 'HEAD'),
  \   'rtp': get(opts, 'rtp', ''),
  \   'do': s:gets(opts, ['do', 'run', 'build'], [''])[0],
  \   'frozen': s:gets(opts, ['frozen', 'lock'], [v:false])[0],
  \   'dir': s:gets(opts, ['dir', 'path'], [''])[0],
  \   'on': on,
  \   'opt': !empty(on) || get(opts, 'opt'),
  \   'path': path,
  \   'status': [s:status.pending],
  \   'output': '',
  \   'code': get(opts, 'hook_add', ''),
  \   'setup': s:gets(opts, ['setup', 'hook_add', 'hook_source'], [''])[0],
  \   'config': s:gets(opts, ['config', 'hook_post_source'], [''])[0],
  \   'requires': requires,
  \ }
  let pkg.merged = get(opts, 'merged', s:is_merged(pkg))
  let s:declared_packages[name] = pkg
  call s:execute(pkg.code)
endfunction

function! jetpack#load_toml(path) abort
  let lines = readfile(a:path)
  let toml = jetpack#parse_toml(lines)
  for [name, options] in items(toml)
    call jetpack#add(name, options)
  endfor
endfunction

function! jetpack#begin(...) abort
  " In lua, passing nil and no argument are synonymous, but in practice, v:null is passed.
  if a:0 > 0 && a:1 != v:null
    let s:home = expand(a:1)
    execute 'set runtimepath^=' . expand(s:home)
    execute 'set packpath^=' . expand(s:home)
  elseif has('nvim')
    let s:home = stdpath('data') . '/' . 'site'
  elseif has('win32')
    let s:home = expand('~/vimfiles')
  else
    let s:home = expand('~/.vim')
  endif
  let s:optdir = s:home . '/pack/jetpack/opt'
  let s:srcdir = s:home . '/pack/jetpack/src'
  let s:declared_packages = {}
  let available_packages_file = s:optdir . '/available_packages.json'
  let available_packages_text =
        \ filereadable(available_packages_file)
        \ ? join(readfile(available_packages_file)) : "{}"
  let s:available_packages = json_decode(available_packages_text)
  augroup Jetpack
    autocmd!
  augroup END
  command! -nargs=+ -bar Jetpack call jetpack#add(<args>)
endfunction

function! s:doautocmd(ord, pkg_name) abort
  let pkg = jetpack#get(a:pkg_name)
  if jetpack#tap(a:pkg_name) || (pkg.local && isdirectory(pkg.path.'/'.pkg.rtp))
    let pattern_a = 'jetpack_' . a:pkg_name . '_' . a:ord
    let pattern_a = substitute(pattern_a, '\W\+', '_', 'g')
    let pattern_a = substitute(pattern_a, '\(^\|_\)\(.\)', '\u\2', 'g')
    let pattern_b = 'Jetpack' . substitute(a:ord, '.*', '\u\0', '') . ':'. a:pkg_name
    for pattern in [pattern_a, pattern_b]
      if exists('#User#' . pattern)
        execute 'doautocmd <nomodeline> User' pattern
      endif
    endfor
  endif
endfunction

" Not called during startup
function! jetpack#load(pkg_name) abort
  let pkg = get(s:available_packages, a:pkg_name, {})
  if !jetpack#tap(a:pkg_name) || pkg.merged
    return v:false
  endif
  " Load package
  call s:doautocmd('pre', a:pkg_name)
  call s:packadd(a:pkg_name)
  for file in glob(pkg.path . '/after/plugin/*', '', 1)
    execute 'source' file
  endfor
  call s:doautocmd('post', a:pkg_name)
  return v:true
endfunction

" Original: https://github.com/junegunn/vim-plug/blob/e3001/plug.vim#L683-L693
"  License: MIT, https://raw.githubusercontent.com/junegunn/vim-plug/e3001/LICENSE
function! s:load_map(map, names, with_prefix, prefix)
  for name in a:names
    call jetpack#load(name)
  endfor
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

function! s:load_cmd(cmd, names, ...) abort
  execute 'delcommand' a:cmd
  for name in a:names
    call jetpack#load(name)
  endfor
  let args = a:0>0 ? join(a:000, ' ') : ''
  try
    execute a:cmd args
  catch /.*/
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
endfunction

function! jetpack#end() abort
  delcommand Jetpack
  command! -bar JetpackSync call jetpack#sync()

  syntax off
  filetype plugin indent off

  if sort(keys(s:declared_packages)) != sort(keys(s:available_packages))
    echomsg 'Some packages are not synchronized. Run :JetpackSync'
  endif

  for [pkg_name, pkg] in items(s:declared_packages)
    for dep_name in pkg.requires
      let cmd = 'call jetpack#load('.string(dep_name).')'
      let pattern = 'JetpackPre:'.pkg_name
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': pattern, 'cmd': cmd, 'once': v:true }])
    endfor
    if !empty(pkg.setup)
      let pattern = 'JetpackPre:'.pkg_name
      let cmd = 'call s:execute(s:declared_packages['.string(pkg_name).'].setup)'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': pattern, 'cmd': cmd, 'once': v:true }])
    endif
    if !empty(pkg.config)
      let pattern = 'JetpackPost:'.pkg_name
      let cmd = 'call s:execute(s:declared_packages['.string(pkg_name).'].config)'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': pattern, 'cmd': cmd, 'once': v:true }])
    endif
    if !empty(pkg.dir) || pkg.local
      let cmd = 'call s:doautocmd("pre", '.string(pkg_name).')'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': 'JetpackSetup', 'cmd': cmd, 'once': v:true }])
      execute 'set runtimepath^=' . pkg.path . '/' . pkg.rtp
      execute 'set runtimepath+=' . pkg.path . '/' . pkg.rtp . '/after'
      let cmd = 'call s:doautocmd("post", '.string(pkg_name).')'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': 'JetpackConfig', 'cmd': cmd, 'once': v:true }])
      continue
    endif
    if !pkg.opt
      let cmd = 'call s:doautocmd("pre", '.string(pkg_name).')'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': 'JetpackSetup', 'cmd': cmd, 'once': v:true }])
      call s:packadd(pkg_name, '!')
      let cmd = 'call s:doautocmd("post", '.string(pkg_name).')'
      call s:autocmd_add([{ 'group': 'Jetpack', 'event': 'User', 'pattern': 'JetpackConfig', 'cmd': cmd, 'once': v:true }])
      continue
    endif
    for it in pkg.on
      if it =~? '^<Plug>'
        let s:maps[it] = add(get(s:maps, it, []), pkg_name)
        execute printf('inoremap <silent> %s <C-\><C-O>:<C-U>call <SID>load_map(%s, %s, 0, "")<CR>', it, string(it), s:maps[it])
        execute printf('nnoremap <silent> %s :<C-U>call <SID>load_map(%s, %s, 1, "")<CR>', it, string(it), s:maps[it])
        execute printf('vnoremap <silent> %s :<C-U>call <SID>load_map(%s, %s, 1, "gv")<CR>', it, string(it), s:maps[it])
        execute printf('onoremap <silent> %s :<C-U>call <SID>load_map(%s, %s, 1, "")<CR>', it, string(it), s:maps[it])
      elseif exists('##'.substitute(it, ' .*', '', ''))
        let cmd = 'call jetpack#load('.string(pkg_name).')'
        let [event, pattern] = split(it . (it =~# ' ' ? '' : ' *'), ' ')
        call s:autocmd_add([{ 'group': 'Jetpack', 'event': event, 'pattern': pattern, 'cmd': cmd, 'once': v:true }])
      else
        let cmd = substitute(it, '^:', '', '')
        let s:cmds[cmd] = add(get(s:cmds, cmd, []), pkg_name)
        execute printf('command! -range -nargs=* %s :call <SID>load_cmd(%s, %s, <f-args>)', cmd, string(cmd), s:cmds[cmd])
      endif
    endfor
  endfor
  call s:packadd('_', '!')

  autocmd Jetpack SourcePre */jetpack/opt/*/plugin/**/* ++once doautocmd <nomodeline> Jetpack User JetpackSetup
  autocmd Jetpack VimEnter * ++once doautocmd <nomodeline> Jetpack User JetpackConfig

  syntax enable
  filetype plugin indent on
endfunction


" s:ask() from junegunn/plug.vim
" https://github.com/junegunn/vim-plug/blob/ddce935b16fbaaf02ac96f9f238deb04d4d33a31/plug.vim#L316-L324
" MIT License: https://github.com/junegunn/vim-plug/blob/88cc9d78687dd309389819f85b39368a4fd745c8/LICENSE
function! s:ask(message, ...)
  call inputsave()
  echohl WarningMsg

  let answer = input(a:message.(a:0 ? ' (y/N/a) ' : ' (y/N) '))
  echohl None
  call inputrestore()
  echo "\r"
  return (a:0 && answer =~? '^a') ? 2 : (answer =~? '^y') ? 1 : 0
endfunction

function! jetpack#tap(name) abort
  return has_key(s:available_packages, a:name) && has_key(s:declared_packages, a:name)
endfunction

function! jetpack#names() abort
  return keys(s:declared_packages)
endfunction

function! jetpack#get(name) abort
  return get(s:declared_packages, a:name, {})
endfunction

if !has('nvim') | finish | endif
lua<<========================================
local Jetpack = {}

for _, name in pairs({'begin', 'end', 'add', 'names', 'get', 'tap', 'sync', 'load'}) do
  Jetpack[name] = function(...)
    local result = vim.fn['jetpack#' .. name](...)
    return result == 0 and false or result == 1 and true or result
  end
end
Jetpack.prologue = Jetpack['begin']
Jetpack.epilogue = Jetpack['end']

Jetpack.startup = function(config)
  vim.cmd([[echomsg 'require("jetpack").startup() is deprecated.]] ..
          [[Please use require("jetpack.packer").startup() .']])
  Packer.startup(config)
end

Jetpack.setup = function(config)
  vim.cmd([[echomsg 'require("jetpack").setup() is deprecated.]] ..
          [[Please use require("jetpack.paq")() .']])
  Paq(config)
end

package.preload['jetpack'] = function()
  return Jetpack
end

local Packer = {
  option = {},
}

Packer.init = function(option)
  if option.package_root then
    option.package_root = vim.fn.fnamemodify(option.package_root, ":h")
    option.package_root = string.gsub(option.package_root, '\\', '/')
  end
  Packer.option = option
end

local function create_hook(name, value)
  local fun = type(value) == 'function' and value or assert(loadstring(value))
  local dump = vim.fn.string(string.dump(fun))
  return
    "lua if require('jetpack').tap('"..name.."') then "..
    "  assert(loadstring(vim.api.nvim_eval('"..dump.."')))() "..
    "end"
end

local function use(plugin)
  if type(plugin) == 'string' then
    Jetpack.add(plugin)
  else
    local repo = table.remove(plugin, 1)
    if next(plugin) == nil then
      Jetpack.add(repo)
    else
      local name = plugin['as'] or string.gsub(repo, '.*/', '')
      if plugin.setup then
        plugin.setup = create_hook(name, plugin.setup)
      end
      if plugin.config then
        plugin.config = create_hook(name, plugin.config)
      end
      Jetpack.add(repo, plugin)
    end
  end
end

Packer.startup = function(config)
  Jetpack.prologue(Packer.option.package_root)
  config(use)
  Jetpack.epilogue()
end

Packer.add = function(config)
  Jetpack.prologue()
  for _, plugin in pairs(config) do
    use(plugin)
  end
  Jetpack.epilogue()
end

package.preload['jetpack.packer'] = function()
  return Packer
end

local Paq = function(config)
  Jetpack.prologue()
  for _, plugin in pairs(config) do
    use(plugin)
  end
  Jetpack.epilogue()
end

package.preload['jetpack.paq'] = function()
  return Paq
end

========================================
