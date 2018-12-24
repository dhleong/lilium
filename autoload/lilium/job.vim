
func! lilium#job#Start(command, Callback)
    let info = {
        \ 'buffer': "",
        \ 'onDone': a:Callback
        \ }

    func! info.onOutput(channel, msg) dict
        let self.buffer = self.buffer . a:msg
    endfunc

    func! info.onExit(channel, code) dict
        call self.onDone(self.buffer)
    endfunc

    return job_start(a:command, {
        \ 'out_cb': info.onOutput,
        \ 'out_mode': 'raw',
        \ 'exit_cb': info.onExit,
        \ })
endfunc

func! s:CallDecoded(Callback, encoded)
    let json = json_decode(a:encoded)
    call a:Callback(json)
endfunc

func! lilium#job#StartJson(command, Callback)
    let WrappedCallback = function('s:CallDecoded', [a:Callback])
    return lilium#job#Start(a:command, WrappedCallback)
endfunc
