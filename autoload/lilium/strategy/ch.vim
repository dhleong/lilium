
func! s:findPrefix(beforeOnLine) "{{{
    return matchstr(a:beforeOnLine, '[#@][[:alnum:]-]*$')
endfunc "}}}

func! s:getEntitiesForPrefix(prefix) " {{{
    let wordField = ''
    let menuField = ''
    let matchField = ''

    let type = a:prefix[0]
    let prefix = a:prefix[1:] " trim the # or @
    if type ==# '#'
        let items = lilium#entities#Get('issues')
        let wordField = 'id'
        let menuField = 'name'
        let matchField = 'name'
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
endfunc " }}}

let s:ch_base = {
    \ 'findPrefix': function('s:findPrefix'),
    \ 'getEntitiesForPrefix': function('s:getEntitiesForPrefix'),
    \ }

func! lilium#strategy#ch#create()
    let curl = lilium#strategy#ch#curl#create()
    if type(curl) != type(0)
        return extend(deepcopy(s:ch_base), curl)
    endif

    return 0
endfunc

