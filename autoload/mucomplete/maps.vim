" Chained completion that works as I want!
" Maintainer: Lifepillar <lifepillar@lifepillar.me>
" License: This file is placed in the public domain
" Auxiliary Script: for mappings generation, by mg979 <mg1979.git@gmail.com>

" Mappings are checked at start and on BufEnter (where buffer mappings could
" override MUcomplete mappings). Mappings are only generated if necessary (on
" the base of options and vim version).

" Whenever a mapping is existing, the old mapping is reconstructed with
" maparg(), and the new mapping takes the for of:
"
"       <expr> pumvisible() ? new_mapping : old_mapping
"
" An exception is made when the keystrokes are themselves contained in the
" original mapping, to avoid recursions. Example from vim-endwise:
"
"       <CR><Plug>DiscretionaryEnd -> <Plug>(MUcompleteCR)<Plug>DiscretionaryEnd


let s:save_cpo = &cpo
set cpo&vim


" Plugs and Tab mappings {{{1
imap     <silent> <expr> <plug>(MUcompleteFwd)         mucomplete#tab_complete( 1)
imap     <silent> <expr> <plug>(MUcompleteBwd)         mucomplete#tab_complete(-1)
imap     <silent> <expr> <plug>(MUcompleteCycFwd)      mucomplete#cycle( 1)
imap     <silent> <expr> <plug>(MUcompleteCycBwd)      mucomplete#cycle(-1)

if !get(g:, 'mucomplete#no_mappings', get(g:, 'no_plugin_maps', 0))
  if !hasmapto('<plug>(MUcompleteFwd)', 'i')
    imap <unique> <tab> <plug>(MUcompleteFwd)
  endif
  if !hasmapto('<plug>(MUcompleteBwd)', 'i')
    imap <unique> <s-tab> <plug>(MUcompleteBwd)
  endif
endif

" On plugin loaded {{{1
fun! mucomplete#maps#start()
  let [s:old, s:new] = [{}, {}]
  let can_map = !(get(g:, 'mucomplete#no_popup_mappings', 0) ||
        \         get(g:, 'mucomplete#no_mappings', 0) ||
        \         get(g:, 'no_plugin_maps', 0))

  if !has('patch-8.0.0283') && can_map
    inoremap <silent> <expr> <plug>(MUcompletePopupCancel) mucomplete#auto#popup_exit("\<c-e>")
    inoremap <silent> <expr> <plug>(MUcompletePopupAccept) mucomplete#auto#popup_exit("\<c-y>")
    inoremap <silent> <expr> <plug>(MUcompleteCR)          mucomplete#auto#popup_exit("\<cr>")
    let s:old  = {'<cr>': 'OldCR', '<c-y>': 'OldCy', '<c-e>': 'OldCe'}
    let s:new  = {'<cr>': 'CR', '<c-y>': 'PopupAccept', '<c-e>': 'PopupCancel'}
  endif

  for m in keys(s:old)
    let mp = maparg(m, 'i', 0, 1)
    let [old, new] = [s:plug(s:old[m]), s:plug(s:new[m])]

    if (empty(mp) || mp.buffer) && !hasmapto(new, 'i')
      execute 'imap <silent> <unique> '.m.' '.new
      continue
    endif

    call s:make_maps(m, mp, old, new, ' ')
  endfor

  " add <bs> to the active mappings, that will be checked on BufEnter
  if get(g:, 'mucomplete#prevent_popup_on_backspace', 1) && s:map_bs()
    inoremap <silent> <expr> <plug>(MUcompleteBS) mucomplete#auto#check_chars_before()
    let s:old['<bs>'] = 'BS'
    let s:new['<bs>'] = 'BS'
  endif
endfun

" On BufEnter {{{1
fun! mucomplete#maps#buffer()
  for m in keys(s:old)
    let mp = maparg(m, 'i', 0, 1)
    let [old, new] = [s:plug(s:old[m]), s:plug(s:new[m])]

    if empty(mp) || !mp.buffer
      continue
    endif

    call s:make_maps(m, mp, old, new, ' <buffer> ')
  endfor
endfun

" Helpers {{{1
fun! s:plug(p)
  return '<Plug>(MUcomplete'.a:p.')'
endfun

fun! s:make_maps(m, mp, old, new, b)
  let e = a:mp['expr']    ? '<expr> '    : ''
  let s = a:mp['silent']  ? '<silent> '  : ''
  let M = a:mp['noremap'] ? 'inoremap '  : 'imap '
  let w = a:mp['nowait']  ? '<nowait> '  : ''
  let r = a:mp['rhs']
  if match(maparg(a:m, 'i'), a:m) >= 0
    let old = substitute(maparg(a:m, 'i'), a:m, '', 'g')
    exe 'imap ' . a:b . a:m . ' ' . a:new . old
  else
    exe M.e.s.w . ' ' . a:old . ' ' . r
    exe 'imap <expr>' . a:b . a:m . ' pumvisible() ? ' . '"\'.a:new.'"' . ' : ' . '"\'.a:old.'"'
  endif
endfun

fun! s:map_bs()
  let has_patch = has('patch-8.0.1494')
  let map_bs    = get(g:, 'mucomplete#map_backspace_for_popup_prevention', !has_patch)

  if map_bs && !hasmapto('<plug>(MUcompleteBS)', 'i')
    " no TextChangedP, or forcing <bs> remapping for better performance
    imap <silent> <unique> <bs> <plug>(MUcompleteBS)
    return 1

  elseif has_patch
    " TextChangedP and not forcing <bs> remapping, use autocmd

    autocmd TextChangedP * noautocmd if col('.') <= 2 || s:nopopup(-2)
          \ | call feedkeys("\<c-e>", 'n') | endif
  endif
endfun

let &cpo = s:save_cpo
unlet s:save_cpo

