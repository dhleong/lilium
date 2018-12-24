
func! lilium#strategy#create() " {{{
    let curl = lilium#strategy#curl#create()
    let hub = lilium#strategy#hub#create()
    if type(hub) != type(0)
        let hub.usersAsync = curl.usersAsync
        return hub
    endif

    return lilium#strategy#dummy#create()
endfunc " }}}
