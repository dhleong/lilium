func! lilium#pr#Create(...) " {{{
    let extra = []
    if a:0 == 1 && type(a:1) == type(extra)
        let extra = a:1
    else
        let extra = a:000
    endif
    let args = extend(['gh', 'pr', 'create'], extra)
    call lilium#util#editor#Run(args, {
        \ 'enhanced': 1,
        \ })
endfunc " }}}
