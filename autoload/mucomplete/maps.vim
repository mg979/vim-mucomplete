" Chained completion that works as I want!
" Maintainer: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain
" Auxiliary Script: mg979 <mg1979.git@gmail.com>

" This script handles:
"       - mapping generation on first InsertEnter event.
"       - popup prevention on backspace

inoremap <silent>        <plug>(MUcompleteFwdKey)    <c-j>
inoremap <silent>        <plug>(MUcompleteBwdKey)    <c-h>
imap     <silent> <expr> <plug>(MUcompleteFwd)       mucomplete#tab_complete( 1)
imap     <silent> <expr> <plug>(MUcompleteBwd)       mucomplete#tab_complete(-1)
imap     <silent> <expr> <plug>(MUcompleteCycFwd)    mucomplete#cycle( 1)
imap     <silent> <expr> <plug>(MUcompleteCycBwd)    mucomplete#cycle(-1)
imap     <silent> <expr> <plug>(MUcompleteAlternate) mucomplete#change_chain()

augroup MUcompleteBuffer
  au!
  autocmd TextChangedI  * noautocmd let g:mucomplete#current_chain = g:mucomplete#chains
augroup END

if !has('patch-8.0.0283')
  inoremap <silent> <expr> <plug>(MUcompletePopupCancel) mucomplete#auto#popup_exit("\<c-e>")
  inoremap <silent> <expr> <plug>(MUcompletePopupAccept) mucomplete#auto#popup_exit("\<c-y>")
  inoremap <silent> <expr> <plug>(MUcompleteCR)          mucomplete#auto#popup_exit("\<cr>")
else
  inoremap <silent> <plug>(MUcompletePopupCancel) <c-e>
  inoremap <silent> <plug>(MUcompletePopupAccept) <c-y>
  inoremap <silent> <plug>(MUcompleteCR)          <cr>
endif



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" On first InsertEnter {{{1

fun! mucomplete#maps#init()

  " Remove augroup, so that it runs only once
  autocmd! MUcompleteInit
  augroup! MUcompleteInit

  " Get plugins variables before any change is done
  call mucomplete#plugins#insert_enter()

  " Basic mappings
  if !get(g:, 'mucomplete#no_mappings', get(g:, 'no_plugin_maps', 0))
    if !hasmapto('<plug>(MUcompleteFwd)', 'i')
      call s:map('imap', '<tab>', '<plug>(MUcompleteFwd)')
    endif
    if !hasmapto('<plug>(MUcompleteBwd)', 'i')
      call s:map('imap', '<s-tab>', '<plug>(MUcompleteBwd)')
    endif
    if !hasmapto('<plug>(MUcompleteCycFwd)', 'i')
      call s:map('imap', '<c-j>', '<plug>(MUcompleteCycFwd)')
    endif
    if !hasmapto('<plug>(MUcompleteCycBwd)', 'i')
      call s:map('imap', '<c-h>', '<plug>(MUcompleteCycBwd)')
    endif
    if get(g:, 'mucomplete#map_cspace', 0)
      let p = has('nvim') || has('gui_running') ? "c-space" : "nul"
      call s:map('imap', '<'.p.'>', mucomplete#plugins#cspace())
    endif
  endif

  " Compatibility mappings
  if mucomplete#compat#requires_mappings()
    call s:map('imap', '<c-e>', mucomplete#plugins#cte())
    call s:map('imap', '<c-y>', mucomplete#plugins#cty())
    call s:map('imap', '<cr>', mucomplete#plugins#cr())
  elseif exists('g:loaded_youcompleteme')
    call s:map('imap', '<c-e>', mucomplete#plugins#cte())
    call s:map('imap', '<c-y>', mucomplete#plugins#cty())
  endif

  " Map <bs> if appropriate
  if s:map_bs()
    inoremap <silent> <expr> <plug>(MUcompleteBS) mucomplete#maps#check_chars_before()
    call s:map('imap', '<bs>', mucomplete#plugins#bs())
  endif

  " Finalize plugin compatibility
  call mucomplete#plugins#ready()
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Prevent popup when backspacing if the c-n completion would be triggered {{{1

fun! s:nopopup(off)
  for c in get(b:, 'mucomplete_no_popup_after_chars',
        \          get(g:, 'mucomplete#no_popup_after_chars', ['\s', '"', nr2char(39)]))
    if s:charpos(col('.') + a:off) =~ c
      return 1
    endif
  endfor
endfun

fun! s:charpos(col)
  return matchstr(getline('.'), '\%' . a:col . 'c.')
endfun

fun! s:map_bs()
  let has_patch = has('patch-8.0.1494')
  let map_bs    = get(g:, 'mucomplete#map_backspace_for_popup_prevention', !has_patch)

  if map_bs && !hasmapto('<plug>(MUcompleteBS)', 'i')
    " no TextChangedP, or forcing <bs> remapping for better performance
    return 1

  elseif has_patch
    " TextChangedP and not forcing <bs> remapping, use autocmd

    call mucomplete#maps#bs_augroup()
  endif
endfun

fun! mucomplete#maps#check_chars_before()
  if has_key(b:, 'mucomplete_ycm')
    return "\<BS>"
  else
    return pumvisible() && ( col('.') <= 3 || s:nopopup(-3) )
          \? "\<c-e>\<BS>" : "\<BS>"
  endif
endf

fun! mucomplete#maps#bs_augroup()
  augroup MUcompleteBS
    au!
    autocmd TextChangedP * noautocmd if col('.') <= 2 || s:nopopup(-2)
          \ | call feedkeys("\<c-e>", 'n') | endif
  augroup END
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers {{{1

fun! s:map(mode, lhs, rhs, ...)
  try
    execute a:mode '<silent> <unique>' a:lhs a:rhs
  catch /^Vim\%((\a\+)\)\=:E227/
    if get(g:, 'mucomplete#force_mappings', []) == ['*']
          \|| index(get(g:, 'mucomplete#force_mappings', []), lhs) >= 0
      execute a:mode '<silent>' a:lhs a:rhs
    else
      call s:errmsg(a:lhs . ' is already mapped (use `:verbose '.a:mode.' '.a:lhs.'` to see by whom). See :help mucomplete-compatibility.')
    endif
  endtry
endf

fun! s:errmsg(msg)
  echohl ErrorMsg
  echomsg "[MUcomplete]" a:msg
  echohl NONE
endf

