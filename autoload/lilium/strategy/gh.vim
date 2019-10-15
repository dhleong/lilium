func! lilium#strategy#gh#findPrefix(beforeOnLine) "{{{
    return matchstr(a:beforeOnLine, '[#@][[:alnum:]-]*$')
endfunc "}}}

func! s:completionCandidates(prefix) "{{{
    let wordField = ''
    let menuField = ''
    let matchField = ''

    let type = a:prefix[0]
    let prefix = a:prefix[1:] " trim the # or @
    if type ==# '#'
        " TODO: support cross-repo refs
        let items = lilium#entities#Get('issues', '@gh')
        let wordField = 'number'
        let menuField = 'title'
        let matchField = 'title'
    elseif type ==# '@'
        let items = lilium#entities#Get('users', '@gh')
        let wordField = 'login'
        let matchField = 'login'
    endif

    if wordField ==# ''
        return {}
    endif

    return {
        \ 'prefix': prefix,
        \ 'items': map(copy(items), "extend(v:val, {
        \   'word': type . get(v:val, wordField),
        \   'menu': get(v:val, menuField, ''),
        \ })"),
        \ 'matchField': matchField,
        \ }
endfunc "}}}

let s:gh_base = {
    \ 'findPrefix': function('lilium#strategy#gh#findPrefix'),
    \ 'completionCandidates': function('s:completionCandidates'),
    \ }

func! lilium#strategy#gh#create()
    let curl = lilium#strategy#gh#curl#create()
    if type(curl) != type(0)
        return extend(deepcopy(s:gh_base), curl)
    endif

    return 0
endfunc
