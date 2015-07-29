if !exists("g:go_fmt_command")
    let g:go_fmt_command = "gofmt"
endif

if !exists("g:go_goimports_bin")
    let g:go_goimports_bin = "goimports"
endif

if !exists('g:go_fmt_fail_silently')
    let g:go_fmt_fail_silently = 0
endif

if !exists('g:go_fmt_options')
    let g:go_fmt_options = ''
endif

if !exists("g:go_fmt_experimental")
    let g:go_fmt_experimental = 0
endif

let s:got_fmt_error = 0

function! go#fmt_better#Format(withGoimport)
    " get the command first so we can test it
    let fmt_command = g:go_fmt_command
    if a:withGoimport  == 1 
        let fmt_command  = g:go_goimports_bin
    endif

    " if it's something else than gofmt, we need to check the existing of that
    " binary. For example if it's goimports, let us check if it's installed,
    " if not the user get's a warning via go#tool#BinPath()
    if fmt_command != "gofmt"
        " check if the user has installed goimports
        let bin_path = go#tool#BinPath(fmt_command) 
        if empty(bin_path) 
            return 
        endif

        let fmt_command = bin_path
    endif

    " populate the final command with user based fmt options
    let command = fmt_command . ' -w ' . g:go_fmt_options

    " execute our command...
    let out = system(command . " " . shellescape(bufname("%")))
    let splitted = split(out, '\n')

    if v:shell_error == 0
        " only clear quickfix if it was previously set, this prevents closing
        " other quickfixes
        if s:got_fmt_error 
            let s:got_fmt_error = 0
            call setqflist([])
            cwindow
        endif

        " reload
        let l:winview = winsaveview()
        edit
        call winrestview(l:winview)
    elseif g:go_fmt_fail_silently == 0 
        "otherwise get the errors and put them to quickfix window
        let errors = []
        for line in splitted
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                            \"lnum":     tokens[2],
                            \"col":      tokens[3],
                            \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        if !empty(errors)
            call setqflist(errors, 'r')
            echohl Error | echomsg "Gofmt returned error" | echohl None
        endif
        let s:got_fmt_error = 1
        cwindow
    endif
endfunction
