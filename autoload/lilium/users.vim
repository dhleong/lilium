" TODO we should refactor this to be shared with issues
func! lilium#users#Get()
    let existing = get(b:, '_lilium_users', 0)
    if type(existing) != type(0)
        return existing
    endif

    echom "TODO fetch users blocking"
    return []
endfunc

func! lilium#users#OnFetch(bufnr, users)
    let b:fetched = a:users
    let existing = getbufvar(a:bufnr, '_lilium_users', [])
    let new = existing + a:users
    call setbufvar(a:bufnr, '_lilium_users', new)
endfunc

func! lilium#users#Prefetch()
    let repo = lilium#gh#get()
    call repo.usersAsync(function('lilium#users#OnFetch', [bufnr('%')]))
endfunc
