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
inoremap <silent> <expr> <plug>(MUcompleteBS)        mucomplete#maps#check_chars_before()

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

  " Reset augroup, so that it runs only once
  augroup MUcompleteInit
    au!
  augroup END

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
      if has('nvim') || has('gui_running')
        imap <c-space> <plug>(MUcompleteAlternate)
      else
        imap <nul> <plug>(MUcompleteAlternate)
      endif
    endif
  endif

  " Compatibility mappings
  if !has('patch-8.0.0283') && !(
        \         get(g:, 'mucomplete#no_popup_mappings', 0) ||
        \         get(g:, 'mucomplete#no_mappings', 0) ||
        \         get(g:, 'no_plugin_maps', 0))
    call s:map('imap', '<c-e>', '<plug>(MUcompletePopupCancel)')
    call s:map('imap', '<c-y>', '<plug>(MUcompletePopupAccept)')
    call s:map('imap', '<cr>', '<plug>(MUcompleteCR)')
  endif

  " map <bs> if appropriate
  if s:map_bs() && !hasmapto('<plug>(MUcompleteBS)', 'i')
    call s:map('imap', '<bs>', '<plug>(MUcompleteBS)')
  endif
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Prevent popup when backspacing if the c-n completion would be triggered {{{1
" Currently working only is mucomplete#enable_auto_at_startup is true

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

    autocmd TextChangedP * noautocmd if col('.') <= 2 || s:nopopup(-2)
          \ | call feedkeys("\<c-e>", 'n') | endif
  endif
endfun

fun! mucomplete#maps#check_chars_before()
  return pumvisible() && ( col('.') <= 3 || s:nopopup(-3) )
        \? "\<c-e>\<BS>" : "\<BS>"
endf


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers {{{1

fun! s:map(mode, lhs, rhs)
  try
    execute a:mode '<silent> <unique>' a:lhs a:rhs
  catch /^Vim\%((\a\+)\)\=:E227/
    if get(g:, 'mucomplete#force_mappings', 0)
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

