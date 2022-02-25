function! lilium#repoDir() " {{{
    return fugitive#repo().dir()
endfunction " }}}

func! lilium#gh() " {{{
    " NOTE: You should prefer lilium#project() if you don't need a
    " github-specific instance
    let gh = lilium#strategy#gh#create()
    if type(gh) != type(0)
        return gh
    endif

    return lilium#strategy#dummy#create()
endfunc " }}}

func! lilium#project() " {{{
    let existing = get(b:, '_lilium_project', 0)
    if type(existing) != type(0)
        return existing
    endif

    let inst = lilium#strategy#create()
    let b:_lilium_project = inst
    return inst
endfunc " }}}

func! lilium#Enable() " {{{
    if exists('b:_lilium_init')
        return
    endif

    let p = lilium#project()
    if !p.exists()
        return
    endif

    if !has('nvim')
        call lilium#complete#Enable()
        call lilium#entities#PrefetchAll()
    endif

    let b:_lilium_init = 1
endfunc " }}}
