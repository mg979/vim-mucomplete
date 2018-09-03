" Chained completion that works as I want!
" Maintainer: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

let s:save_cpo = &cpo
set cpo&vim

fun! mucomplete#auto#enable()
  augroup MUcompleteAuto
    autocmd!
    autocmd InsertCharPre * noautocmd call mucomplete#auto#insertcharpre()
    if get(g:, 'mucomplete#delayed_completion', 0)
      autocmd TextChangedI * noautocmd call mucomplete#auto#ic_auto_complete()
      autocmd  CursorHoldI * noautocmd call mucomplete#auto#auto_complete()
    else
      autocmd TextChangedI * noautocmd call mucomplete#auto#auto_complete()
    endif
  augroup END
endf

fun! mucomplete#auto#disable()
  if exists('#MUcompleteAuto')
    autocmd! MUcompleteAuto
    augroup! MUcompleteAuto
  endif
endf

fun! mucomplete#auto#toggle()
  if exists('#MUcompleteAuto')
    call mucomplete#auto#disable()
    echomsg '[MUcomplete] Auto off'
  else
    call mucomplete#auto#enable()
    echomsg '[MUcomplete] Auto on'
  endif
endf

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

fun! mucomplete#auto#check_chars_before()
  return pumvisible() && ( col('.') <= 3 || s:nopopup(-3) )
        \? "\<c-e>\<BS>" : "\<BS>"
endf

if get(g:, 'mucomplete#prevent_popup_on_backspace', 1)
  let has_patch = has('patch-8.0.1494')
  let map_bs    = get(g:, 'mucomplete#map_backspace_for_popup_prevention', !has_patch)

  if !has_patch || map_bs
    " no TextChangedP, or forcing <bs> remapping for better performance

    if !(get(g:, 'mucomplete#no_popup_mappings', 0) || get(g:, 'mucomplete#no_mappings', 0) || get(g:, 'no_plugin_maps', 0))
      inoremap    <silent> <expr> <plug>(MUcompleteBS) mucomplete#auto#check_chars_before()
      call mucomplete#map('imap', '<bs>', '<plug>(MUcompleteBS)')
    endif

  elseif has_patch && !map_bs
    " TextChangedP and not forcing <bs> remapping, use autocmd

    autocmd TextChangedP * noautocmd if col('.') <= 2 || s:nopopup(-2)
                                 \ | call feedkeys("\<c-e>", 'n') | endif
  endif
endif

if has('patch-8.0.0283') " {{{1
  let s:insertcharpre = 0

  fun! mucomplete#auto#insertcharpre()
    let s:insertcharpre = !pumvisible() && (v:char =~# '\m\S')
  endf

  fun! mucomplete#auto#ic_auto_complete()
    if mode(1) ==# 'ic'  " In Insert completion mode, CursorHoldI in not invoked
      call mucomplete#auto_complete()
    endif
  endf

  fun! mucomplete#auto#auto_complete()
    if s:insertcharpre || mode(1) ==# 'ic'
      let s:insertcharpre = 0
      call mucomplete#auto_complete()
    endif
  endf

  let &cpo = s:save_cpo
  unlet s:save_cpo

  finish
endif

" Code for Vim 8.0.0282 and older {{{1
if !(get(g:, 'mucomplete#no_popup_mappings', 0) || get(g:, 'mucomplete#no_mappings', 0) || get(g:, 'no_plugin_maps', 0))
  if !hasmapto('<plug>(MUcompletePopupCancel)', 'i')
    call mucomplete#map('imap', '<c-e>', '<plug>(MUcompletePopupCancel)')
  endif
  if !hasmapto('<plug>(MUcompletePopupAccept)', 'i')
    call mucomplete#map('imap', '<c-y>', '<plug>(MUcompletePopupAccept)')
  endif
  if !hasmapto('<plug>(MUcompleteCR)', 'i')
    call mucomplete#map('imap', '<cr>', '<plug>(MUcompleteCR)')
  endif
endif

let s:cancel_auto = 0
let s:insertcharpre = 0

fun! mucomplete#auto#popup_exit(keys)
  let s:cancel_auto = pumvisible()
  return a:keys
endf

fun! mucomplete#auto#insertcharpre()
  let s:insertcharpre = (v:char =~# '\m\S')
endf

fun! mucomplete#auto#ic_auto_complete()
  if s:cancel_auto
    let s:cancel_auto = 0
    return
  endif
  if !s:insertcharpre
    call mucomplete#auto_complete()
  endif
endf

fun! mucomplete#auto#auto_complete()
  if s:cancel_auto
    let [s:cancel_auto, s:insertcharpre] = [0,0]
    return
  endif
  if s:insertcharpre
    let s:insertcharpre = 0
    call mucomplete#auto_complete()
  endif
endf

let &cpo = s:save_cpo
unlet s:save_cpo

