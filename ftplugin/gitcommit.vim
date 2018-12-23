
"
" On-demand loading. Let's use the autoload folder and not slow down vim's
" startup procedure.
augroup liliumStart
  autocmd!
  autocmd BufEnter <buffer> call lilium#Enable()
augroup END


