
func! lilium#strategy#create() " {{{
    let curl = lilium#strategy#curl#create()
    if type(curl) != type(0)
        return curl
    endif

    " let hub = lilium#strategy#hub#create()

    " if type(hub) != type(0)
    "     if type(curl) != type(0)
    "         let hub.usersAsync = curl.usersAsync
    "     endif
    "
    "     return hub
    " endif

    return lilium#strategy#dummy#create()
endfunc " }}}
