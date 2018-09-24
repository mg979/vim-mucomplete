" Chained completion that works as I want!
" Maintainer: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain

if exists("g:loaded_mucomplete")
  finish
endif
let g:loaded_mucomplete = 1

let s:save_cpo = &cpo
set cpo&vim

call mucomplete#init(1, 1)
let g:mucomplete#plugins = mucomplete#plugins#init()

if has('patch-7.4.143') || (v:version == 704 && has("patch143")) " TextChangedI started to work there
  command -bar -nargs=0 MUcompleteAutoOn call mucomplete#auto#enable()
  command -bar -nargs=0 MUcompleteAutoOff call mucomplete#auto#disable()
  command -bar -nargs=0 MUcompleteAutoToggle call mucomplete#auto#toggle()

  augroup MUcompleteInit
    au!
    autocmd InsertEnter * noautocmd call mucomplete#maps#init() |
          \ if get(g:, 'mucomplete#enable_auto_at_startup', 0) |
          \     call mucomplete#auto#enable() |
          \ endif |
          \ call mucomplete#plugins#ready()
  augroup END
endif

let &cpo = s:save_cpo
unlet s:save_cpo

