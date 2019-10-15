
func! lilium#strategy#ch#findPrefix(beforeOnLine) "{{{
    return matchstr(a:beforeOnLine, '\m\(\[ch\|#\)[[:alnum:]-]*$')
endfunc "}}}

func! s:completionCandidates(prefix) " {{{
    if a:prefix =~# '^\[ch'
        let prefix = a:prefix[3:] " trim [ch
    elseif a:prefix =~# '^#'
        let prefix = a:prefix[1:] " trim #
    else
        return {}
    endif

    let items = lilium#entities#Get('issues', '@ch')

    return {
        \ 'prefix': prefix,
        \ 'items': map(copy(items), "extend(v:val, {
        \   'word': '[ch' . v:val.id . '](' . v:val.app_url . ')',
        \   'menu': v:val.name,
        \ })"),
        \ 'matchField': 'name',
        \ }
endfunc " }}}

let s:ch_base = {
    \ 'findPrefix': function('lilium#strategy#ch#findPrefix'),
    \ 'completionCandidates': function('s:completionCandidates'),
    \ }

func! lilium#strategy#ch#create()
    let curl = lilium#strategy#ch#curl#create()
    if type(curl) != type(0)
        return extend(deepcopy(s:ch_base), curl)
    endif

    return 0
endfunc

