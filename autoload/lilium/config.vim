func! lilium#config#FindFile(name)
    let parents = count(expand('%:p:h'), '/') - 1
    let path = './'

    for i in range(0, parents)
        let found = findfile(path . a:name)
        if found !=# '' && filereadable(found)
            return found
        endif

        let path = './.' . path
    endfor

    return ''
endfunc
