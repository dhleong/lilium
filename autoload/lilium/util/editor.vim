" TempScript based on the same from fugitive: {{{
if !exists('s:temp_scripts')
    let s:temp_scripts = {}
endif

if !exists('s:editor_name')
    if has('nvim')
        let s:editor_name = 'nvim'
    else
        let s:editor_name = 'vim'
    endif
endif

func! s:TempScript(...)
    let lines = flatten(copy(a:000))
    let body = join(lines, "\n")
    let g:body_args = lines

    if !has_key(s:temp_scripts, body)
        " the script name is visible in gh, so let's make it look like "vim"
        let scriptDir = tempname()
        call mkdir(scriptDir, 'p')
        let s:temp_scripts[body] = scriptDir . '/' . s:editor_name
    endif

    let temp = s:temp_scripts[body]
    if !filereadable(temp)
        call writefile(['#!/bin/sh'] + lines, temp)
        call setfperm(temp, 'rwxrwxrwx')
    endif
    return s:temp_scripts[body]
endfunc " }}}

func! s:RestoreTerm(state) " {{{
    exe a:state.windowSize .'split'
    exe 'buffer ' . a:state.termBufnr
    startinsert

    call writefile([], a:state.temp . '.exit')
endfunc " }}}

func! s:FinishEditing(editorBufnr, termBufnr) " {{{
    augroup liliumEditor
        autocmd!
    augroup END

    let state = getbufvar(a:termBufnr, 'lilium_editor_state')
    let state.windowSize = winheight(bufwinnr(a:editorBufnr))
    let state.termBufnr = a:termBufnr

    " TODO can we actually avoid a flash caused by destroying
    " the window? here, we basically just try to "restore"
    " the window to the previous size...
    call timer_start(10, { -> s:RestoreTerm(state) })
endfunc " }}}

func! s:OnEdit(bufnr, args) " {{{
    let [path] = a:args
    let g:lilium_editing = path
    let state = getbufvar(a:bufnr, 'lilium_editor_state')

    setlocal bufhidden=hide

    exe 'edit ' . path

    if state.enhanced
        let b:_lilium_project = state.project
        call lilium#Enable()
    endif

    let editorBufnr = bufnr('%')

    augroup liliumEditor
        autocmd!
        exe 'autocmd BufWinLeave <buffer> call <SID>FinishEditing(' . editorBufnr . ',' . a:bufnr . ')'
    augroup END
endfunc " }}}

func! s:CreateOnEditScriptVim(sid)
    let callback = ['call',  a:sid . 'OnEdit', ['$editing']]
    return 'printf "\033]51;' . escape(json_encode(callback), '"') . '\007"'
endfunc

func! s:CreateOnEditScriptNeovim(bufnr, sid)
    return [
        \ 'nvim -u NONE -i NONE -es << EOF',
        \ "let sock = sockconnect('pipe', '$NVIM_LISTEN_ADDRESS', { 'rpc': 1 })",
        \ "call rpcrequest(sock, 'nvim_exec', " .
        \   "'call " . a:sid . 'OnEdit(' . a:bufnr . ", [\"$editing\"])'," .
        \   '0)',
        \ 'call chanclose(sock)',
        \ 'EOF',
        \ ]
endfunc

func! lilium#util#editor#Run(cmd, ...) " {{{
    let config = a:0 ? a:1 : {}
    let project = lilium#project()
    let sid = expand('<SID>')
    let bufnr = 0

    let onEditScript = ''
    if has('nvim')
        split
        enew
        let bufnr = bufnr('%')
        let onEditScript = s:CreateOnEditScriptNeovim(bufnr, sid)
    else
        let onEditScript = s:CreateOnEditScriptVim(sid)
    endif

    let editor = s:TempScript(
          \ '[ -f "$LILIUM_TEMP.exit" ] && exit 1',
          \ 'editing="$1"',
          \ 'while [ ! -f "$editing" -a ! -f "$LILIUM_TEMP.exit" ]; do sleep 0.05 2>/dev/null || sleep 1; done',
          \ onEditScript,
          \ 'while [ ! -f "$LILIUM_TEMP.exit" ]; do sleep 0.05 2>/dev/null || sleep 1; done',
          \ 'exit 0')

    let state = extend(config, {
        \ 'project': project,
        \ 'temp': tempname(),
        \ })

    let env = {
        \ 'EDITOR': editor,
        \ 'NVIM_LISTEN_ADDRESS': v:servername,
        \ 'LILIUM_TEMP': state.temp,
        \ }

    if has('nvim')
        call termopen(a:cmd, { 'env': env })
        startinsert
    else
        let bufnr = term_start(a:cmd, {
            \ 'env': env,
            \ 'term_api': sid,
            \ })
    endif
    call setbufvar(bufnr, 'lilium_editor_state', state)

    if bufnr != 0
        nnoremap <buffer> <silent> gq :q<cr>
        nnoremap <buffer> <silent> q :q<cr>
    endif
endfunc " }}}
