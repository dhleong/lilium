func! s:findPrefix(beforeOnLine) "{{{
    return matchstr(a:beforeOnLine, '[#@][[:alnum:]-]*$')
endfunc "}}}

func! s:getEntitiesForPrefix(prefix) "{{{
    let wordField = ''
    let menuField = ''
    let matchField = ''

    let type = a:prefix[0]
    let prefix = a:prefix[1:] " trim the # or @
    if type ==# '#'
        " TODO: support cross-repo refs
        let items = lilium#entities#Get('issues')
        let wordField = 'number'
        let menuField = 'title'
        let matchField = 'title'
    elseif type ==# '@'
        let items = lilium#entities#Get('users')
        let wordField = 'login'
        let matchField = 'login'
    endif

    if wordField ==# ''
        return {}
    endif

    return {
        \ 'type': type,
        \ 'prefix': prefix,
        \ 'items': items,
        \ 'wordField': wordField,
        \ 'menuField': menuField,
        \ 'matchField': matchField,
        \ }
endfunc "}}}

let s:gh_base = {
    \ 'findPrefix': function('s:findPrefix'),
    \ 'getEntitiesForPrefix': function('s:getEntitiesForPrefix'),
    \ }

func! lilium#strategy#gh#create()
    let curl = lilium#strategy#gh#curl#create()
    if type(curl) != type(0)
        return extend(deepcopy(s:gh_base), curl)
    endif

    return 0
endfunc
