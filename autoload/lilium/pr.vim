func! lilium#pr#Create(...) " {{{
    let args = extend(['gh', 'pr', 'create'], a:000)
    call lilium#util#editor#Run(args, {
        \ 'enhanced': 1,
        \ })
endfunc " }}}
