"
" Github interaction abstractions
"

func! lilium#gh#get()
    let existing = get(b:, '_lilium_gh', 0)
    if type(existing) != type(0)
        return existing
    endif

    let inst = lilium#strategy#create()
    let b:_lilium_gh = inst
    return inst
endfunc

func! lilium#gh#repo()
    return lilium#gh#get().repo()
endfunc
