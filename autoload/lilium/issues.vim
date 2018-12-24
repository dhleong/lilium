func! lilium#issues#Get()
    let existing = get(b:, '_lilium_issues', 0)
    if type(existing) != type(0)
        return existing
    endif

    echom "TODO fetch issues blocking"
    return []
endfunc

func! lilium#issues#OnFetch(bufnr, issues)
    let existing = getbufvar(a:bufnr, '_lilium_issues', [])
    let new = existing + a:issues
    call setbufvar(a:bufnr, '_lilium_issues', new)
endfunc

func! lilium#issues#Prefetch()
    let repo = lilium#gh#get()
    call repo.issuesAsync(function('lilium#issues#OnFetch', [bufnr('%')]))
endfunc
