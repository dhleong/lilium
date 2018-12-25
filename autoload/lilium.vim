function! lilium#repoDir() " {{{
    return fugitive#repo().dir()
endfunction " }}}

func! lilium#gh() " {{{
    let existing = get(b:, '_lilium_gh', 0)
    if type(existing) != type(0)
        return existing
    endif

    let inst = lilium#strategy#create()
    let b:_lilium_gh = inst
    return inst
endfunc " }}}

func! lilium#Enable() " {{{
    if exists('b:_lilium_init')
        return
    endif

    let repo = lilium#gh().repo()
    if repo ==# ''
        return
    endif

    call lilium#complete#Enable()

    call lilium#entities#PrefetchAll()

    let b:_lilium_init = 1
endfunc " }}}
