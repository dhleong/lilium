"
" Entity caching
"

func! s:KeyOf(kind)
    return '_lilium_' . a:kind
endfunc

func! lilium#entities#Get(kind, ...)
    let key = s:KeyOf(a:kind)
    let existing = get(b:, key, 0)
    if type(existing) != type(0)
        if a:0
            return filter(copy(existing), 'v:val.source ==# a:1')
        endif
        return existing
    endif

    echom 'TODO fetch ' . a:kind . ' blocking'
    return []
endfunc

func! lilium#entities#OnFetch(kind, bufnr, source, entities)
    if type(a:entities) != type([])
        return
    endif
    let key = s:KeyOf(a:kind)
    let existing = getbufvar(a:bufnr, key, [])
    let new = existing + map(a:entities, "extend(v:val, {
        \ 'source': a:source,
        \ })")
    call setbufvar(a:bufnr, key, new)
endfunc

func! lilium#entities#Prefetch(kind)
    let project = lilium#project()
    let Callback = function('lilium#entities#OnFetch', [a:kind, bufnr('%')])
    call project[a:kind . 'Async'](Callback)
endfunc

func! lilium#entities#PrefetchAll()
    call lilium#entities#Prefetch('issues')
    call lilium#entities#Prefetch('users')
endfunc
