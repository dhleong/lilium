let s:plugin_root = expand('<sfile>:p:h:h:h:h')

function lilium#util#path#PluginRoot() abort
    return s:plugin_root
endfunction
