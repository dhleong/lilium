"
" `hub`-based strategy
"

func! s:processIssues(Callback, channel, msg)
    let parts = split(a:msg, ':')
    if len(parts) < 2
        return
    endif

    call a:Callback([{
        \ 'number': parts[0],
        \ 'title': parts[1],
        \ }])
endfunc

func! lilium#strategy#hub#create()
    let config = lilium#strategy#hub#config#Find()
    if config ==# ''
        return 0
    endif

    let s = {}
    func! s.repo() dict
        return lilium#strategy#hub#config#GetRepoPath()
    endfunc

    func! s.repoUrl() dict
        return lilium#strategy#hub#config#GetRepoUrl()
    endfunc

    func! s.issuesAsync(Callback) dict
        let JobCb = function('<SID>processIssues', [a:Callback])
        call job_start('hub issue -f %I:%t%n', {
            \ 'callback': JobCb,
            \ 'out_mode': 'nl',
            \ })
    endfunc

    func! s.usersAsync(Callback) dict
        " nop; Hub doesn't support listing collaborators
    endfunc

    return s
endfunc
