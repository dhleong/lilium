"
" `curl`-based asana strategy
"

func s:readConfig()
    let path = lilium#config#FindFile('.lilium.asana.json')
    if path ==# '' || !filereadable(path)
        return {}
    endif

    let contents = readfile(path)
    return json_decode(join(contents))
endfunc

func! s:unpack(Callback, json)
    if has_key(a:json, 'data')
        call a:Callback('@asana', a:json.data)
    else
        echom "Error:" . string(a:json)
    endif
endfunc

" ======= project impl ====================================

func! s:asana_curl(path, params) dict
    let token = self._config.token

    " NOTE: this is not very rigorous, but it's sufficient for our needs:
    let params = []
    for k in keys(a:params)
        call add(params, k . '=' . a:params[k])
    endfor

    return ['curl', '--silent', '-X', 'GET',
        \ '-H', 'Content-Type: application/json',
        \ '-H', 'Authorization: Bearer ' . token,
        \ '-L',
        \ 'https://app.asana.com/api/1.0' . a:path
        \ . '?' . join(params, '&')
        \ ]
endfunc

func! s:asana_typeahead(type, Callback) dict
    let url = '/workspaces/' . self._config.workspace . '/typeahead'
    let curl = self._curl(url, {
        \ 'resource_type': a:type,
        \ })
    call lilium#job#StartJson(curl, function('s:unpack', [a:Callback]))
endfunc

func s:asana_exists() dict
    return self._config.token !=# ''
endfunc

func s:asana_repo() dict
    return '' " TODO ?
endfunc

func s:asana_repoUrl() dict
    return '' " TODO ?
endfunc

func s:asana_usersAsync(Callback) dict
    return self._typeahead('user', a:Callback)
endfunc

func s:asana_issuesAsync(Callback) dict
    return self._typeahead('task', a:Callback)
endfunc

let s:strategy = {
    \ '_curl': function('<SID>asana_curl'),
    \ '_typeahead': function('<SID>asana_typeahead'),
    \ 'exists': function('<SID>asana_exists'),
    \ 'repo': function('<SID>asana_repo'),
    \ 'repoUrl': function('<SID>asana_repoUrl'),
    \ 'usersAsync': function('<SID>asana_usersAsync'),
    \ 'issuesAsync': function('<SID>asana_issuesAsync'),
    \ }

" ======= public interface ================================

func! lilium#strategy#asana#curl#create()
    " ensure we have access to curl
    if !executable('curl')
        return 0
    endif

    let config = s:readConfig()
    if empty(config)
        return 0
    endif

    let s = deepcopy(s:strategy)
    let s._config = config
    return s
endfunc
