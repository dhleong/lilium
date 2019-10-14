
func! lilium#strategy#create() " {{{
    " TODO composite strategy

    let ch = lilium#strategy#ch#create()
    if type(ch) != type(0)
        return ch
    endif

    let gh = lilium#strategy#gh#create()
    if type(gh) != type(0)
        return gh
    endif

    " let hub = lilium#strategy#gh#hub#create()

    " if type(hub) != type(0)
    "     if type(curl) != type(0)
    "         let hub.usersAsync = curl.usersAsync
    "     endif
    "
    "     return hub
    " endif

    return lilium#strategy#dummy#create()
endfunc " }}}
