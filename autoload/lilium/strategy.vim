
func! lilium#strategy#create()
    let hub = lilium#strategy#hub#create()
    if type(hub) != type(0)
        return hub
    endif

    return lilium#strategy#dummy#create()
endfunc
