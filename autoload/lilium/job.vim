
func! lilium#job#Start(command, Callback)
    let info = {
        \ 'buffer': "",
        \ 'command': a:command,
        \ 'onDone': a:Callback
        \ }

    func! info.onOutput(channel, msg) dict
        let self.buffer = self.buffer . a:msg
    endfunc

    func! info.onClose(channel) dict
        call self.onDone(self.buffer)
    endfunc

    func! info.onExit(channel, code) dict
        if a:code != 0
            echom "Job `" . self.command . "` exited with: " . a:code
        endif
    endfunc

    return job_start(a:command, {
        \ 'out_cb': info.onOutput,
        \ 'out_mode': 'raw',
        \ 'close_cb': info.onClose,
        \ 'exit_cb': info.onExit,
        \ })
endfunc

func! s:CallDecoded(Callback, encoded)
    let json = json_decode(a:encoded)
    if type(json) == type(v:none) && json == v:none
        " not valid json
        echom "Bad Json: " . a:encoded
        return
    endif
    call a:Callback(json)
endfunc

func! lilium#job#StartJson(command, Callback)
    let WrappedCallback = function('s:CallDecoded', [a:Callback])
    return lilium#job#Start(a:command, WrappedCallback)
endfunc
