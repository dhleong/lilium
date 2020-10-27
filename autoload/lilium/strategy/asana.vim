let s:issue_url = 'https://app.asana.com/0/0/'

func! lilium#strategy#asana#findPrefix(beforeOnLine) "{{{
    return matchstr(a:beforeOnLine, '\m\([a]\?#\)[[:alnum:]-]*$')
endfunc "}}}

func! s:completionCandidates(prefix) " {{{
    if a:prefix =~# '^a#'
        let prefix = a:prefix[2:] " trim a#
    elseif a:prefix =~# '^#'
        let prefix = a:prefix[1:] " trim #
    else
        return {}
    endif

    let items = lilium#entities#Get('issues', '@asana')
    return {
        \ 'prefix': prefix,
        \ 'items': map(copy(items), "extend(v:val, {
        \   'word': s:issue_url . v:val.gid,
        \   'menu': v:val.name,
        \ })"),
        \ 'matchField': 'name',
        \ }
endfunc " }}}

let s:asana_base = {
    \ 'findPrefix': function('lilium#strategy#asana#findPrefix'),
    \ 'completionCandidates': function('s:completionCandidates'),
    \ }

func! lilium#strategy#asana#create()
    let curl = lilium#strategy#asana#curl#create()
    if type(curl) != type(0)
        return extend(deepcopy(s:asana_base), curl)
    endif

    return 0
endfunc
