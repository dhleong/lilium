
func! lilium#strategy#create() " {{{
    let composite = lilium#strategy#composite#create([
        \ lilium#strategy#ch#create(),
        \ lilium#strategy#gh#create(),
        \ ])

    if type(composite) != type(0)
        return composite
    endif

    return lilium#strategy#dummy#create()
endfunc " }}}
