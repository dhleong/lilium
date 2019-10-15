"
" `curl`-based github strategy
"

func! s:curl(path)
    let token = lilium#strategy#gh#hub#config#ReadToken()
    let curl = 'curl --silent -H "Authorization: token ' . token . '" '
    return curl . 'https://api.github.com' . a:path
endfunc

func! s:curlRepo(path)
    let repo = lilium#strategy#gh#hub#config#GetRepoPath()
    return s:curl('/repos/' . repo . a:path)
endfunc

func! lilium#strategy#gh#curl#_repo(path)
    return s:curlRepo(a:path)
endfunc

func! lilium#strategy#gh#curl#create()
    " ensure we have access to curl
    if !executable('curl')
        return 0
    endif

    " NOTE: we currently only pull the token from the hub config
    let token = lilium#strategy#gh#hub#config#ReadToken()
    if token ==# ''
        return 0
    endif

    let s = {}
    func! s.exists() dict
        return self.repo() !=# ''
    endfunc

    func! s.repo() dict
        return lilium#strategy#gh#hub#config#GetRepoPath()
    endfunc

    func! s.repoUrl() dict
        return lilium#strategy#gh#hub#config#GetRepoUrl()
    endfunc

    func! s.usersAsync(Callback) dict
        let curl = s:curlRepo('/contributors')
        call lilium#job#StartJson(curl, function(a:Callback, ['@gh']))
    endfunc

    func! s.issuesAsync(Callback) dict
        let curl = s:curlRepo('/issues')
        call lilium#job#StartJson(curl, function(a:Callback, ['@gh']))
    endfunc

    return s
endfunc