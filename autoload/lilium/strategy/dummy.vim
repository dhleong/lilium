"
" Dummy strategy, when nothing else is configured
"

func! s:lambda(returnValue)
    return a:returnValue
endfunc

func! lilium#strategy#dummy#create()
    return {
        \ 'repo': function('<SID>lambda', ['']),
        \ 'issuesAsync': function('<SID>lambda', [0])
        \ }
endfunc
