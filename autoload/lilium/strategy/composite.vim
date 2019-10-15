
func! s:findPrefix(beforeOnLine) dict " {{{
    for s in self._strategies
        let p = s.findPrefix(a:beforeOnLine)
        if !empty(p)
            return p
        endif
    endfor

    return ''
endfunc " }}}

func! s:completionCandidates(prefix) dict " {{{
    let composite = {
        \ 'prefix': a:prefix,
        \ 'items': [],
        \ 'matchField': 'compositeMatch',
        \ }
    for s in self._strategies
        let result = s.completionCandidates(a:prefix)
        if empty(result) || empty(result.items)
            continue
        endif

        if has_key(result, 'prefix')
            " these should match given the same input prefix, I would think?
            let composite.prefix = result.prefix
        endif

        " NOTE: the input should already have copied the items,
        " so another copy here is probably wasteful
        let composite.items = composite.items + map(result.items, "extend(v:val, {
            \   'compositeMatch': get(v:val, result.matchField),
            \ })")
    endfor

    return composite
endfunc " }}}

func! s:onEachStrategy(fnName, ...) dict " {{{
    for s in self._strategies
        let Fn = get(s, a:fnName, 0)
        if type(Fn) == type(0)
            continue
        endif

        let WithArgs = function(Fn, a:000, s)
        call WithArgs()
    endfor
endfunc " }}}

let s:strategy = {
    \ 'exists': { -> 1 },
    \ 'findPrefix': function('s:findPrefix'),
    \ 'completionCandidates': function('s:completionCandidates'),
    \ 'usersAsync': function('s:onEachStrategy', ['usersAsync']),
    \ 'issuesAsync': function('s:onEachStrategy', ['issuesAsync']),
    \ }

" ======= public interface ================================

func! lilium#strategy#composite#create(strategies)
    let strategies = filter(copy(a:strategies),
        \ 'type(v:val) == type({}) && v:val.exists()')

    if empty(strategies)
        return 0
    elseif len(strategies) == 1
        " only one? don't bother compositing
        return strategies[0]
    endif

    return extend(deepcopy(s:strategy), {
        \ '_strategies': strategies,
        \ })
endfunc
