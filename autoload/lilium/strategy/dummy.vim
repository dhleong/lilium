"
" Dummy strategy, when nothing else is configured
"

func! s:lambda(returnValue)
    return a:returnValue
endfunc

func! lilium#strategy#dummy#create()
    return {
        \ 'exists': function('<SID>lambda', [0]),
        \ 'repo': function('<SID>lambda', ['']),
        \ 'repoUrl': function('<SID>lambda', ['']),
        \ 'issuesAsync': function('<SID>lambda', [0])
        \ }
endfunc
