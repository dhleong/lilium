
" ======= YCM interop =====================================

func! s:HasYCM() " {{{
    return exists('#youcompleteme')
endfunc " }}}

let s:ycmEnabled = 1
func! s:SetYCMEnabled(isEnabled) " {{{
    if !s:HasYCM()
        return
    endif

    if a:isEnabled == s:ycmEnabled
        " nothing to do
        return
    endif
    let s:ycmEnabled = a:isEnabled

    if a:isEnabled
        call youcompleteme#EnableCursorMovedAutocommands()
    else
        call youcompleteme#DisableCursorMovedAutocommands()
    endif
endfunc " }}}


" ======= Internal utils ==================================

func! s:LineBeforeCursor() " {{{
    let line = getline('.')
    let cursor = col('.')

    if cursor >= col('$') - 1
        return line
    endif

    " col is 1-indexed; line is 0-indexed
    let cursor = cursor - 1
    if cursor <= 0
        return ''
    endif

    " -1 for BEFORE the cursor (in insert mode)
    return line[0:cursor - 1]
endfunc " }}}

func! s:FeedKeys(keys) " {{{
    call feedkeys(a:keys, 'in')
endfunc " }}}

func! s:FindPrefix(...) " {{{
    let before_on_line = s:LineBeforeCursor()
    if a:0
        " NB: Sometimes the most-recent character
        "  is lost when we trigger this from within
        "  filter completion; that character is exactly
        "  a suffix on this line, so we'll be given it
        let before_on_line = before_on_line . a:1
    endif

    return matchstr(before_on_line, '[#@][[:alnum:]-]*$')
endfunc " }}}

func! s:CloseCompletionMenu() " {{{
    if pumvisible()
        call s:SendKeys( "\<C-e>" )
    endif
endfunc " }}}

func! s:GetFilteredCompletionsFor(prefix) " {{{
    let type = a:prefix[0]
    let prefix = a:prefix[1:] " trim the # or @
    let items = []
    let wordField = ''
    let menuField = ''
    let matchField = ''

    try
        if type ==# '#'
            " TODO: support cross-repo refs
            let items = lilium#issues#Get()
            let wordField = 'number'
            let menuField = 'title'
            let matchField = 'title'
        elseif type ==# '@'
            let items = lilium#users#Get()
            let wordField = 'login'
            let matchField = 'login'
        endif
    catch
        echo 'Unable to load completions'
        return {}
    endtry

    if type(items) != type([])
        " no completions; possibly not a github repo
        return {}
    endif

    let filtered = filter(copy(items),
        \ 'lilium#match#do(v:val, prefix, matchField)')
    return {
        \ 'type': type,
        \ 'completions': filtered,
        \ 'wordField': wordField,
        \ 'menuField': menuField
        \ }
endfunc " }}}

func! s:OnTextChangedInsertMode() " {{{
    let prefix = s:FindPrefix()
    if prefix != ''
        call s:SetYCMEnabled(0)
        call s:TriggerComplete(prefix)
    else
        call s:SetYCMEnabled(1)
    endif
endfunc " }}}

func! s:OnInsertChar() " {{{
    if v:char == '#' || v:char == '@'
        call s:SetYCMEnabled(0)
    endif
endfunc " }}}

func! s:TriggerComplete(prefix) " {{{
    if len(a:prefix) == 0
        return
    endif

    " if no filtered completions are available, just close the menu.
    " otherwise, vim seems to just hang until you enter a space
    let result = s:GetFilteredCompletionsFor(a:prefix)
    if !has_key(result, 'completions') || len(result.completions) == 0
        call s:CloseCompletionMenu()
        return
    endif

    if !s:HasYCM()
        if len(a:prefix) == 1
            " with just the prefix, we simply use <c-p> to clear to the prefix
            call s:FeedKeys("\<C-X>\<C-O>\<C-P>")
        else
            " with more than just the prefix typed, we use <c-n><c-p> to get back
            " to what we originally typed
            call s:FeedKeys("\<C-X>\<C-O>\<C-N>\<C-P>")
        endif
    else
        " with YCM this 'just works,' apparently
        " (once we disable its autocmds)
        call s:FeedKeys("\<C-X>\<C-O>\<C-P>")
    endif
endfunc " }}}


" ======= Public interface ================================

func! lilium#complete#func(findstart, base, ...) " {{{
    " let repo_dir = lilium#repoDir()
    " if repo_dir ==# ''
    "     return a:findstart ? -1 : []
    " endif

    let b:lily_start = a:findstart
    if a:findstart
        let prefix = a:0 ? s:FindPrefix(a:1) : s:FindPrefix()
        let cursor = col('.')
        if cursor <= 2
            return 0
        endif
        let start = cursor - 1 - strlen(prefix)
        let b:_start = start
        return start
    endif

    let prefix = a:base
    if prefix ==# ''
        " Still nothing? Okay; return -2 means 'stay in
        "  completion mode'
        return -2
    endif

    let result = s:GetFilteredCompletionsFor(prefix)
    if !has_key(result, 'completions')
        " stop completion
        return -3
    endif

    let words = map(result.completions, "{
        \ 'word': result.type . get(v:val, result.wordField),
        \ 'menu': empty(result.menuField) ? '' : get(v:val, result.menuField),
        \ 'icase': 1
        \ }")

    return {'words': words, 'refresh': 'always'}
endfunc " }}}

func! lilium#complete#Enable() " {{{
    setlocal omnifunc=lilium#complete#func

    " We need menuone in completeopt, otherwise when there's only one candidate
    " for completion, the menu doesn't show up.
    set completeopt-=menu
    set completeopt+=menuone

    augroup liliumcursormoved
        autocmd!
        autocmd TextChangedI <buffer> call s:OnTextChangedInsertMode()
        autocmd InsertCharPre <buffer> call s:OnInsertChar()
        autocmd InsertLeave * call s:SetYCMEnabled(1)
    augroup END
endfunc " }}}
