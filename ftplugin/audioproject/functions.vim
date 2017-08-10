nnoremap <buffer> <space> :call <SID>Play(line("."))<cr>

function! s:Play(lnum)
    let args = <SID>ParseLine(getline(a:lnum))
    execute "silent !(cd " . expand("%:p:h") . "; play -q " . args . ")"
endfunction

function! s:ParseLine(line)
    return a:line
endfunction
