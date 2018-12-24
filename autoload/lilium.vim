function! lilium#repoDir() " {{{
    return fugitive#repo().dir()
endfunction " }}}

func! lilium#Enable() " {{{
    if exists('b:_lilium_init')
        return
    endif

    let repo = lilium#gh#repo()
    if repo ==# ''
        return
    endif

    call lilium#complete#Enable()

    call lilium#issues#Prefetch()
    call lilium#users#Prefetch()

    let b:_lilium_init = 1
endfunc " }}}
