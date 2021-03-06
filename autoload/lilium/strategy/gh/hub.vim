"
" `hub`-based github strategy
"

func! s:processIssues(Callback, channel, msg)
    let parts = split(a:msg, ':')
    if len(parts) < 2
        return
    endif

    call a:Callback('@gh', [{
        \ 'number': parts[0],
        \ 'title': parts[1],
        \ }])
endfunc

func! lilium#strategy#gh#hub#create()
    let config = lilium#strategy#gh#hub#config#Find()
    if config ==# ''
        return 0
    endif

    let s = {}
    func! s:exists() dict
        return self.repo() !=# ''
    endfunc

    func! s.repo() dict
        return lilium#strategy#gh#hub#config#GetRepoPath(self)
    endfunc

    func! s.repoUrl() dict
        return lilium#strategy#gh#hub#config#GetRepoUrl(self)
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
