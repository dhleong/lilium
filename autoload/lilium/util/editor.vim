" TempScript borrowed from fugitive: {{{
if !exists('s:temp_scripts')
  let s:temp_scripts = {}
endif

func! s:TempScript(...)
    let body = join(a:000, "\n")
    if !has_key(s:temp_scripts, body)
        let temp = tempname() . '.vim'
        call writefile(['#!/bin/sh'] + a:000, temp)
        let s:temp_scripts[body] = temp
    endif
    return s:temp_scripts[body]
endfunc " }}}

func! s:RestoreTerm(state) " {{{
    call writefile([], a:state.temp . '.exit')

    exe a:state.windowSize .'split'
    exe 'buffer ' . a:state.termBufnr
    startinsert
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

func! lilium#util#editor#OnEdit(bufnr, args) " {{{
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

func! lilium#util#editor#Run(cmd, ...) " {{{
    let config = a:0 ? a:1 : {}
    let project = lilium#project()

    let callback = ["call", "lilium#util#editor#OnEdit", ["$1"]]
    let editor = 'sh ' . s:TempScript(
          \ '[ -f "$LILIUM_TEMP.exit" ] && exit 1',
          \ 'editing="$1"',
          \ 'printf "\033]51;' . escape(json_encode(callback), '"') . '\007"',
          \ 'while [ -f "$editing" -a ! -f "$LILIUM_TEMP.exit" ]; do sleep 0.05 2>/dev/null || sleep 1; done',
          \ 'exit 0')

    let state = extend(config, {
        \ 'project': project,
        \ 'temp': tempname(),
        \ })

    let env = {
        \ 'EDITOR': editor,
        \ 'LILIUM_TEMP': state.temp,
        \ }

    let opts = {
        \ 'env': env,
        \ 'term_api': 'lilium#util#editor#',
        \ }

    let bufnr = term_start(a:cmd, opts)
    call setbufvar(bufnr, 'lilium_editor_state', state)
endfunc " }}}
