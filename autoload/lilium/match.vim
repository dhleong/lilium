"
" Matching functions
"

function! lilium#match#fuzzy(input, haystack) " {{{
    " Fuzzy match

    let haystack = tolower(a:haystack)
    let input = tolower(a:input)
    let hayI = 0
    let inputI = 0

    while inputI < len(input)
        let ch = input[inputI]

        " find ch in haystack (starting from the last position)
        let foundIdx = stridx(haystack, ch, hayI)
        if foundIdx < 0
            " searched the whole haystack for this and couldn't
            " find it; this is not a match
            return 0
        endif

        let hayI = foundIdx + 1
        let inputI += 1
    endwhile

    " all input consumed!
    return 1
endfunction " }}}

function! lilium#match#simple(input, haystack) " {{{
    " Simple, case-insensitive match

    return match(a:haystack, '\c' . a:input) >= 0
endfunction " }}}

function! lilium#match#do(item, input, item_field) " {{{
    " Delegates to whatever matcher the user wants
    let method = g:lilium#prefs#matcher.Get()
    let haystack = get(a:item, a:item_field, '')

    if method ==# 'fuzzy'
        return lilium#match#fuzzy(a:input, haystack)
    endif

    return lilium#match#simple(a:input, haystack)
endfunction " }}}
