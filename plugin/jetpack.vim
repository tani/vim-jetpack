"=============== JETPACK.vim =================
"      The lightning-fast plugin manager
"
"                MIT License
"
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
"=============================================

if exists('g:loaded_jetpack')
  finish
endif
let g:loaded_jetpack = 1

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

let s:packages = get(s:, 'packages', {})

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

" Original: https://github.com/lambdalisue/vital-Whisky/blob/90c71/autoload/vital/__vital__/System/Job/Vim.vim#L46
"  License: https://github.com/lambdalisue/vital-Whisky/blob/90c71/LICENSE
function! s:nvim_exit_cb(buf, cb, job, ...) abort
  let ch = job_getchannel(a:job)
  while ch_status(ch) ==# 'open' | sleep 1ms | endwhile
  while ch_status(ch) ==# 'buffered' | sleep 1ms | endwhile
  call a:cb(join(a:buf, "\n"))
endfunction

function! s:jobstart(cmd, cb) abort
  if has('nvim')
    let buf = []
    return jobstart(a:cmd, {
    \   'on_stdout': { _, data -> extend(buf, data) },
    \   'on_stderr': { _, data -> extend(buf, data) },
    \   'on_exit': { -> a:cb(join(buf, "\n")) }
    \ })
  else
    let buf = []
    return job_start(a:cmd, {
    \   'out_mode': 'raw',
    \   'out_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'err_mode': 'raw',
    \   'err_cb': { _, data -> extend(buf, split(data, "\n")) },
    \   'exit_cb': function('s:nvim_exit_cb', [buf, a:cb])
    \ })
  endif
endfunction

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
    call system(printf('cp -R %s/. %s', shellescape(a:from), shellescape(a:to)))
  elseif has('win32')
    call system(printf('xcopy %s %s /E /Y', shellescape(a:from), shellescape(a:to)))
  endif
endfunction

function! s:setbufline(lnum, text, ...) abort
  call setbufline(bufnr('JetpackStatus'), a:lnum, a:text)
  redraw
endfunction

function! s:setupbuf() abort
  execute 'silent! bdelete! ' . bufnr('JetpackStatus')
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
  let processed = len(filter(copy(s:packages), "v:val.status[-1] =~# 'ed'"))
  call s:setbufline(1, printf('%s (%d / %d)', a:title, processed, len(s:packages)))
  call s:setbufline(2, s:progressbar((0.0 + processed / len(s:packages) * 100)))
  let line_count = 3
  for [pkg_name, pkg] in items(s:packages)
    call s:setbufline(line_count, printf('%s %s', pkg.status[-1], pkg_name))
    let line_count += 1
  endfor
endfunction

function! s:show_result() abort
  call s:setupbuf()
  call s:setbufline(1, printf("Result"))
  call s:setbufline(2, s:progressbar(100))
  let line_count = 3
  for [pkg_name, pkg] in items(s:packages)
    let output = pkg.output
    let output = substitute(output, '\r\n\|\r', '\n', 'g')
    let output = substitute(output, '^From.\{-}\zs\n\s*', '/compare/', '')

    if index(pkg.status, s:status.installed) >= 0
      call s:setbufline(line_count, printf('installed %s', pkg_name))
    elseif index(pkg.status, s:status.updated) >= 0
      call s:setbufline(line_count, printf('updated %s', pkg_name))
    else
      call s:setbufline(line_count, printf('skipped %s', pkg_name))
    endif

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

function! s:clean_plugins() abort
  for [pkg_name, pkg] in items(s:packages)
    if isdirectory(pkg.path)
      "Check the url of the repository
      let remote_url = trim(system(printf('git -C %s ls-remote --get-url', shellescape(pkg.path))))
      if remote_url !=# pkg.url
        call delete(pkg.path, 'rf')
        continue
      endif
      "Check the commit
      if has_key(pkg, 'commit')
        let commit = system(printf('git -C %s cat-file -t %s', shellescape(pkg.path), shellescape(pkg.commit)))
        if commit !~# 'commit'
          call delete(pkg.path, 'rf')
          continue
        endif
      endif
      "Check the branch and the tag
      if has_key(pkg, 'branch') || has_key(pkg, 'tag')
        let branch = trim(system(printf('git -C %s rev-parse --abbrev-ref HEAD', shellescape(pkg.path))))
        if  get(pkg, 'branch', get(pkg, 'tag')) != branch
          call delete(pkg.path, 'rf')
        endif
      endif
    endif
  endfor
endfunction

function! s:update_plugins() abort
  let jobs = []
  for [pkg_name, pkg] in items(s:packages)
    call add(pkg.status, s:status.pending)
  endfor
  for [pkg_name, pkg] in items(s:packages)
    call s:show_progress('Update Plugins')
    if get(pkg, 'frozen') || isdirectory(pkg.path)
      call add(pkg.status, s:status.skipped)
      continue
    else
      call add(pkg.status, s:status.updating)
    endif
    let cmd = ['git', '-C', pkg.path, 'pull', '--rebase']
    let job = s:jobstart(cmd, function({ pkg, output -> [
    \  add(pkg.status, s:status.updated),
    \  execute("let pkg.output = output")
    \ ] }, [pkg]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
endfunction

function! s:install_plugins() abort
  let jobs = []
  for [pkg_name, pkg] in items(s:packages)
    call add(pkg.status, s:status.pending)
  endfor
  for [pkg_name, pkg] in items(s:packages)
    call s:show_progress('Install Plugins')
    if isdirectory(pkg.path)
      call add(pkg.status, s:status.skipped)
      continue
    else
      call add(pkg.status, s:status.installing)
    endif
    let cmd = ['git', 'clone']
    if !has_key(pkg, 'commit')
      call extend(cmd, ['--depth', '1', '--recursive'])
    endif
    if has_key(pkg, 'branch') || has_key(pkg, 'tag')
      call extend(cmd, ['-b', get(pkg, 'branch', get(pkg, 'tag'))])
    endif
    call extend(cmd, [pkg.url, pkg.path])
    let job = s:jobstart(cmd, function({pkg, output -> [
    \   add(pkg.status, s:status.installed),
    \   execute("let pkg.output = output")
    \ ]}, [pkg]))
    call add(jobs, job)
    call s:jobwait(jobs, g:jetpack#njobs)
  endfor
  call s:jobwait(jobs, 0)
endfunction

function! s:switch_plugins() abort
  for [pkg_name, pkg] in items(s:packages)
    call add(pkg.status, s:status.pending)
  endfor
  for [pkg_name, pkg] in items(s:packages)
    call s:show_progress('Switch Plugins')
    if !isdirectory(pkg.path) || !has_key(pkg, 'commit')
      call add(pkg.status, s:status.skipped)
      continue
    else
      call add(pkg.status, s:status.switched)
    endif
    call system(printf('git -C "%s" switch "-"', pkg.path))
    call system(printf('git -C "%s" checkout "%s"', pkg.path, pkg.commit))
  endfor
endfunction

function! s:merge_plugins() abort
  for [pkg_name, pkg] in items(s:packages)
    call add(pkg.status, s:status.pending)
  endfor

  let bundle = {}
  let unbundle = s:packages
  if g:jetpack#optimization == 1
    let unbundle = {}
    for [pkg_name, pkg] in items(s:packages)
      if get(pkg, 'opt') || has_key(pkg, 'do') || has_key(pkg, 'dir')
        let unbundle[pkg_name] = pkg
      else
        let bundle[pkg_name] = pkg
      endif
    endfor
  endif

  call delete(s:optdir, 'rf')
  let destdir = s:path(s:optdir, '_')

  " Merge plugins if possible.
  let merged_count = 0
  let merged_files = {}
  for [pkg_name, pkg] in items(bundle)
    call s:show_progress('Merge Plugins')
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
      let unbundle[pkg_name] = pkg
    else
      for file in files
        let merged_files[file] = v:true
      endfor
      call s:copy(srcdir, destdir)
      call add(pkg.status, s:status.merged)
      let merged_count += 1
    endif
  endfor

  " Copy plugins.
  for [pkg_name, pkg] in items(unbundle)
    call s:show_progress('Copy Plugins')
    if has_key(pkg, 'dir')
      call add(pkg.status, s:status.skipped)
    else
      let srcdir = s:path(pkg.path, get(pkg, 'rtp', ''))
      let destdir = s:path(s:optdir, pkg_name)
      call s:copy(srcdir, destdir)
      call add(pkg.status, s:status.copied)
    endif
  endfor
endfunction

function! s:postupdate_plugins() abort
  silent! packadd _
  for [pkg_name, pkg] in items(s:packages)
    if !has_key(pkg, 'do')
      continue
    endif
    let pwd = getcwd()
    if has_key(pkg, 'dir')
      call chdir(pkg.path)
    else
      execute 'silent! packadd ' . pkg_name
      call chdir(s:path(s:optdir, pkg_name))
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
  call s:clean_plugins()
  call s:update_plugins()
  call s:install_plugins()
  call s:switch_plugins()
  call s:merge_plugins()
  call s:show_result()
  call s:postupdate_plugins()
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
  \   'path': path,
  \   'status': [s:status.pending],
  \   'output': '',
  \ })
  let s:packages[name] = pkg
endfunction

function! jetpack#begin(...) abort
  let s:packages = {}
  if has('nvim')
    let s:home = s:path(stdpath('data'), 'site')
  elseif has('win32')
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

function! s:lod_cmd(cmd, name, ...) abort
  execute printf('delcommand %s', a:cmd)
  execute printf('silent! packadd %s', a:name)
  let args = a:0>0 ? join(a:000, ' ') : ''
  try
    execute printf('%s %s', a:cmd, args)
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
  augroup Jetpack
    autocmd!
  augroup END
  for [pkg_name, pkg] in items(s:packages)
    if has_key(pkg, 'dir')
      let &runtimepath .= printf(',%s/%s', pkg.dir, get(pkg, 'rtp', ''))
      continue
    endif
    if !pkg.opt
      execute 'silent! packadd! ' . pkg_name
      continue
    endif
    let items = get(pkg, 'for', [])
    for it in (type(items) ==# v:t_list ? items : [items])
      execute printf('autocmd Jetpack FileType %s ++once ++nested silent! packadd %s', it, pkg_name)
    endfor
    let items = get(pkg, 'on', [])
    for it in (type(items) ==# v:t_list ? items : [items])
      if it =~? '^<Plug>'
        execute printf('inoremap <silent> %s <C-\><C-O>:<C-U>call <SID>lod_map(%s, %s, 0, "")<CR>', it, string(it), string(pkg_name))
        execute printf('nnoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "")<CR>', it, string(it), string(pkg_name))
        execute printf('vnoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "gv")<CR>', it, string(it), string(pkg_name))
        execute printf('onoremap <silent> %s :<C-U>call <SID>lod_map(%s, %s, 1, "")<CR>', it, string(it), string(pkg_name))
      elseif exists('##'.substitute(it, ' .*', '', ''))
        let it .= (it =~? ' ' ? '' : ' *')
        execute printf('autocmd Jetpack %s ++once ++nested silent! packadd %s', it, pkg_name)
      else
        let cmd = substitute(it, '^:', '', '')
        execute printf('command! -range -nargs=* %s :call <SID>lod_cmd(%s, %s, <f-args>)', cmd, string(cmd), string(pkg_name))
      endif
    endfor
    let event = substitute(pkg_name, '\W\+', '_', 'g')
    let event = substitute(event, '\(^\|_\)\(.\)', '\u\2', 'g')
    execute printf('autocmd Jetpack SourcePre **/pack/jetpack/opt/%s/* ++once ++nested doautocmd User Jetpack%sPre', pkg_name, event)
    execute printf('autocmd Jetpack SourcePost **/pack/jetpack/opt/%s/* ++once ++nested doautocmd User Jetpack%sPost', pkg_name, event)
    execute printf('autocmd Jetpack User Jetpack%sPre :', event)
    execute printf('autocmd Jetpack User Jetpack%sPost :', event)
  endfor
  silent! packadd! _
  syntax enable
  filetype plugin indent on
endfunction

function! jetpack#tap(name) abort
  return has_key(s:packages, a:name) ? isdirectory(jetpack#get(a:name).path) : 0
endfunction

function! jetpack#names() abort
  return keys(s:packages)
endfunction

function! jetpack#get(name) abort
  return get(s:packages, a:name, {})
endfunction

if has('nvim')
lua<<========================================

package.preload['jetpack'] = function()
  local alias = {
    run = 'do',
    ft = 'for'
  }


  local function init(config)
    local config = config or {}

    local function _set_option(name)
      local j_name = 'jetpack#' .. name
      local v = vim.g[j_name]
      vim.g[j_name] = config[name] or vim.g[j_name]
    end

    for _, name in ipairs({'optimization', 'njobs', 'ignore_patterns', 'copy_method'}) do
      _set_option(name)
    end
  end


  local function use(plugin)
    if (type(plugin) == 'string') then
      vim.fn['jetpack#add'](plugin)
    else
      local name = plugin[1]
      plugin[1] = nil
      if vim.fn.type(plugin) == vim.v.t_list then
        vim.fn['jetpack#add'](name)
      else 
        for key, value in pairs(alias) do
          if plugin[key] ~= nil then
            plugin[value] = plugin[key]
          end
        end
        local opts = plugin
        vim.fn['jetpack#add'](name, opts)
      end
    end
  end

  local function startup(config)
    vim.fn['jetpack#begin']()
    config(use)
    vim.fn['jetpack#end']()
  end

  local function setup(config)
    vim.fn['jetpack#begin']()
    for _, plugin in pairs(config) do
      use(plugin)
    end
    vim.fn['jetpack#end']()
  end

  local function tap(name)
    return vim.fn['jetpack#tap'](name) == 1
  end

  return {
    init = init,
    startup = startup,
    setup = setup,
    tap = tap,
    sync = vim.fn["jetpack#sync"],
    names = vim.fn["jetpack#names"],
    get = vim.fn["jetpack#get"]
  }
end

========================================
endif

