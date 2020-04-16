"
" `curl`-based clubhouse strategy
"

func s:readConfig()
    let path = findfile('./.lilium.clubhouse.json')
    if path ==# '' || !filereadable(path)
        return {}
    endif
    let contents = readfile(path)
    return json_decode(join(contents))
endfunc

func! s:unpack(Callback, json)
    call a:Callback('@ch', a:json.data)
endfunc

" ======= project impl ====================================

func! s:ch_curl(path, body) dict
    let token = self._config.token
    return ['curl', '--silent', '-X', 'GET',
        \ '-H', 'Content-Type: application/json',
        \ '-d', json_encode(a:body),
        \ '-L',
        \ 'https://api.clubhouse.io/api/v2' . a:path . '?token=' . token,
        \ ]
endfunc

func s:ch_exists() dict
    return self._config.token !=# ''
endfunc

func s:ch_repo() dict
    return '' " TODO ?
endfunc

func s:ch_repoUrl() dict
    return '' " TODO ?
endfunc

func s:ch_usersAsync(Callback) dict
    call a:Callback('@ch', [])
endfunc

func s:ch_issuesAsync(Callback) dict
    let curl = self._curl('/search/stories', {
        \ 'page_size': 25,
        \ 'query': get(self._config, 'storiesQuery', 'is:story'),
        \ })
    call lilium#job#StartJson(curl, function('s:unpack', [a:Callback]))
endfunc

let s:strategy = {
    \ '_curl': function('<SID>ch_curl'),
    \ 'exists': function('<SID>ch_exists'),
    \ 'repo': function('<SID>ch_repo'),
    \ 'repoUrl': function('<SID>ch_repoUrl'),
    \ 'usersAsync': function('<SID>ch_usersAsync'),
    \ 'issuesAsync': function('<SID>ch_issuesAsync'),
    \ }

" ======= public interface ================================

func! lilium#strategy#ch#curl#create()
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
