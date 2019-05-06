func! s:getter(id, default) " {{{
    let fullId = 'lilium_' . a:id
    if has_key(b:, fullId)
        return get(b:, fullId, a:default)
    endif

    return get(g:, fullId, a:default)
endfunc " }}}

func! s:def(id, default) " {{{

    let id = a:id
    let default = a:default

    let dict = {}
    func! dict.Get() closure
        return s:getter(id, default)
    endfunc

    return dict
endfunc " }}}

let g:lilium#prefs#matcher = s:def('matcher', 'simple')
