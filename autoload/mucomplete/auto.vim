" Chained completion that works as I want!
" Maintainer: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

let s:save_cpo = &cpo
set cpo&vim

fun! mucomplete#auto#enable()
  augroup MUcompleteAuto
    autocmd!
    autocmd BufEnter      * call mucomplete#maps#buffer()
    autocmd InsertCharPre * noautocmd call mucomplete#auto#insertcharpre()
    autocmd TextChangedI  * noautocmd let g:mucomplete#current_chain = g:mucomplete#chains
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

