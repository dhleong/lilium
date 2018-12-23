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

func! lilium#strategy#hub#findConfig()
    let homeConfig = expand("~/.config") . "/hub"
    if filereadable(homeConfig)
        return homeConfig
    endif

    return ""
endfunc

func! lilium#strategy#hub#create()
    let config = lilium#strategy#hub#findConfig()
    if config == ""
        return 0
    endif

    let s = {}
    func! s.repo() dict
        return trim(system("hub browse -u"))
    endfunc

    func! s.issuesAsync(Callback) dict
        let JobCb = function('<SID>processIssues', [a:Callback])
        call job_start("hub issue -f %I:%t%n", {
            \ 'callback': JobCb,
            \ 'out_mode': 'nl',
            \ })
    endfunc

    return s
endfunc
