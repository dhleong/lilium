
func! lilium#strategy#gh#hub#config#Find() " {{
    let homeConfig = expand('~/.config') . '/hub'
    if filereadable(homeConfig)
        return homeConfig
    endif

    return ''
endfunc " }}}

func! lilium#strategy#gh#hub#config#GetRepoUrl() " {{
    let existing = get(b:, '_lilium_repo_url', '')
    if existing !=# ''
        return existing
    endif

    let urlIssues = trim(system('hub browse -u -- issues'))
    if urlIssues =~# '^Aborted' && getcwd() =~# '/.git$'
        let urlIssues = trim(system('cd .. && hub browse -u -- issues'))
    endif
    if urlIssues =~# '^Aborted'
        return ''
    endif

    let url = substitute(urlIssues, '/issues$', '', '')
    let b:_lilium_repo_url = url
    return url
endfunc " }}}

func! lilium#strategy#gh#hub#config#GetRepoHost() " {{
    let url = lilium#strategy#gh#hub#config#GetRepoUrl()
    if url ==# ''
        return ''
    endif

    let m = matchlist(url, 'http[s]*://\([a-zA-Z0-9\.]*\)')
    if len(m) < 2
        return ''
    endif
    return m[1]
endfunc " }}}

func! lilium#strategy#gh#hub#config#GetRepoPath() " {{
    let url = lilium#strategy#gh#hub#config#GetRepoUrl()
    if url ==# ''
        return ''
    endif

    let pathStart = stridx(url, '/', 9)
    return url[pathStart + 1:]
endfunc " }}}


func! lilium#strategy#gh#hub#config#ReadTokens() " {{
    let file = lilium#strategy#gh#hub#config#Find()
    if file ==# ''
        return ''
    endif

    let tokens = {}
    let host = ''
    for line in readfile(file)
        if line[ len(line) - 1 ] ==# ':'
            let host = line[0:len(line) - 2]
        else
            let parts = split(line, ':')
            if trim(parts[0]) ==# 'oauth_token'
                let tokens[host] = trim(parts[1])
            endif
        endif
    endfor

    return tokens
endfunc " }}}

func! lilium#strategy#gh#hub#config#ReadToken() " {{
    let host = lilium#strategy#gh#hub#config#GetRepoHost()
    if host ==# ''
        return ''
    endif

    let tokens = lilium#strategy#gh#hub#config#ReadTokens()
    return get(tokens, host, '')
endfunc " }}}
