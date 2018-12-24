"
" Entity caching
"

func! s:KeyOf(kind)
    return '_lilium_' . a:kind
endfunc

func! lilium#entities#Get(kind)
    let key = s:KeyOf(a:kind)
    let existing = get(b:, key, 0)
    if type(existing) != type(0)
        return existing
    endif

    echom "TODO fetch " . a:kind . " blocking"
    return []
endfunc

func! lilium#entities#OnFetch(kind, bufnr, entities)
    let key = s:KeyOf(a:kind)
    let existing = getbufvar(a:bufnr, key, [])
    let new = existing + a:entities
    call setbufvar(a:bufnr, key, new)
endfunc

func! lilium#entities#Prefetch(kind, ...)
    let repo = lilium#gh()
    let Callback = function('lilium#entities#OnFetch', [a:kind, bufnr('%')])
    let repo = a:0 ? a:1 : ''
    if a:kind == 'issues'
        call gh.issuesAsync(repo, Callback)
    else
        call gh[a:kind . 'Async'](Callback)
    endif
endfunc

func! lilium#entities#PrefetchAll(...)
    let repo = a:0 ? a:1 : ''
    call lilium#entities#Prefetch('issues', repo)
    call lilium#entities#Prefetch('users', repo)
endfunc
