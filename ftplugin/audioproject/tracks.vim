" {{{ Listening and generating functions
function! s:PlayLine(lnum)
    let args = <SID>ParseLine(getline(a:lnum))
    execute "silent !(cd " . expand("%:p:h") . "; play -q " . args . ")"
endfunction

function! s:PlayTrack(lnum)
    let track_line = <SID>WhichTrack(a:lnum)
    let lines = <SID>ParseTrack(track_line)
    execute ":silent !(cd " . expand("%:p:h") . "; play -q " . join(lines) . ")"
endfunction

function! s:GenerateTrack(lnum)
    let track_line = <SID>WhichTrack(a:lnum)
    let track_name = <SID>GetTrackName(track_line)
    let cwd = expand("%:p:h")
    let track_file = cwd . "/" . track_name . ".wav"
    if filereadable(track_file)
        call delete(track_file)
    endif
    let lines = <SID>ParseTrack(track_line)
    execute ":!(cd " . cwd . ";sox " . join(lines) . " " . track_file . ")"
endfunction

" }}}

" {{{ Parsing and structures functions

function! s:ParseLine(line)
    let words = split(a:line)
    let numwords = len(words)
    let idx = 0
    while idx < numwords && !get(g:vimAudioEffects, words[idx], 0)
        let idx += 1
    endwhile
    let final = '"|sox ' . join(words[0:idx-1]) . ' -p ' . join(words[idx:numwords]) . '"'
    return final
endfunction

function! s:ParseTrack(lnum)
    let current_line = a:lnum + 1
    let numlines = line("$")
    let lines = []
    while current_line <= numlines
        let strline = getline(current_line)
        if <SID>IsTrackLine(strline) || strline =~? '\v^\s*$'
            break
        endif
        call add(lines, <SID>ParseLine(strline))
        let current_line += 1
    endwhile
    return lines
endfunction

function! s:WhichTrack(lnum)
    for i in reverse(sort(map(keys(b:tracks), 'str2nr(v:val)')))
        if i < a:lnum
            return i
        endif
    endfor
    return 0
endfunction

function! s:BuildTracks()
    let numlines = line("$")
    let i = 1
    let current_track = '0'
    while i <= numlines
        let content = getline(i)
        if <SID>IsTrackLine(content)
            let current_track = string(i)
            call <SID>AddTrack(i)
        endif
        let i += 1
    endwhile
endfunction

function! s:IsTrackLine(line)
    return a:line =~? '\v^track>.*$'
endfunction

function! s:GetTrackName(lnum)
    let content = getline(a:lnum)
    if content =~? '\v^track\s+\w+>'
        return split(content)[1]
    elseif content =~? '\v^track\s*$'
        return printf("track_%03d", len(keys(b:tracks)))
    else
        return b:tracks[<SID>WhichTrack(a:lnum)].name
    endif
endfunction

function! s:AddTrack(lnum, ...)
    if !a:lnum && a:0
        let track_name = a:1
    elseif a:lnum
        let track_name = <SID>GetTrackName(a:lnum)
    else
        let track_name = "master"
    endif
    let b:tracks[string(a:lnum)] = { 'name': track_name}
endfunction

" }}}
" {{{ Editing functions

function! s:AddLine(lnum)
    let content = getline(a:lnum)
    let words = split(content)
    if <SID>IsTrackLine(content)
        let b:current_track_ref = string(a:lnum)
        call <SID>AddTrack(a:lnum)
    endif
    return "\<CR>"
endfunction

" }}}
" {{{ Listnening mappings
nnoremap <buffer> <space> :call <SID>PlayLine(line("."))<cr>
nnoremap <buffer> <localleader><space> :call <SID>PlayTrack(line("."))<cr>
nnoremap <buffer> <leader><space> :call <SID>PlaySong(line("."))<cr>
nnoremap <buffer> <localleader>gt :call <SID>GenerateTrack(line("."))<cr>

" }}}
" {{{ editing
inoremap <buffer> <cr> <C-R>=<SID>AddLine(line("."))<cr>
" }}}
" {{{ Initialization
if !exists("b:tracks")
    let b:tracks={}
    call <SID>AddTrack(0, 'master')
endif

" {{{ Effects list
if !exists("g:vimAudioEffects")
    let g:vimAudioEffects =  {
        \ 'allpass': 1,
        \ 'band': 1,
        \ 'bandpass': 1,
        \ 'bandreject': 1,
        \ 'bass': 1,
        \ 'bend': 1,
        \ 'biquad': 1,
        \ 'chorus': 1,
        \ 'channels': 1,
        \ 'compand': 1,
        \ 'contrast': 1,
        \ 'dcshift': 1,
        \ 'deemph': 1,
        \ 'delay': 1,
        \ 'dither': 1,
        \ 'downsample': 1,
        \ 'earwax': 1,
        \ 'echo': 1,
        \ 'echos': 1,
        \ 'equalizer': 1,
        \ 'fade': 1,
        \ 'fir': 1,
        \ 'flanger': 1,
        \ 'gain': 1,
        \ 'highpass': 1,
        \ 'hilbert': 1,
        \ 'ladspa': 1,
        \ 'loudness': 1,
        \ 'lowpass': 1,
        \ 'mcompand': 1,
        \ 'noiseprof': 1,
        \ 'noisered': 1,
        \ 'norm': 1,
        \ 'oops': 1,
        \ 'overdrive': 1,
        \ 'pad': 1,
        \ 'phaser': 1,
        \ 'pitch': 1,
        \ 'rate': 1,
        \ 'remix': 1,
        \ 'repeat': 1,
        \ 'reverb': 1,
        \ 'reverse': 1,
        \ 'riaa': 1,
        \ 'silence': 1,
        \ 'sinc': 1,
        \ 'spectrogram': 1,
        \ 'speed': 1,
        \ 'splice': 1,
        \ 'stat': 1,
        \ 'stats': 1,
        \ 'stretch': 1,
        \ 'swap': 1,
        \ 'synth': 1,
        \ 'tempo': 1,
        \ 'treble': 1,
        \ 'tremolo': 1,
        \ 'trim': 1,
        \ 'upsample': 1,
        \ 'vad': 1,
        \ 'vol': 1,
        \ }
endif
" }}}

call <SID>BuildTracks()

" }}}
