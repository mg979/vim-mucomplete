" The variable g:mucomplete#plugin_compatibility is checked.
" Compatibility plugs are generated, but not necessarily assigned.
" Some mappings will be set at mapping generation, others right away.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:autopairs_endwise = 0
let s:autopairs = 0
let s:endwise = 0
let s:ycm = 0
let s:was_auto_enabled = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This function is called on plugin loaded, where it makes sense to change
" default mappings and settings
fun! mucomplete#plugins#init()
  let all = []
  let plugins = get(g:, 'mucomplete#plugin_compatibility', {})
  if has_key(plugins, 'autopairs') && exists('g:AutoPairsLoaded') &&
        \ has_key(plugins, 'endwise') && exists('g:loaded_endwise')
    let s:autopairs_endwise = 1
    call s:remap_autopairs()
    let all = ['autopairs', 'endwise']
  elseif has_key(plugins, 'autopairs') && exists('g:AutoPairsLoaded')
    let s:autopairs = 1
    call s:remap_autopairs()
    let all = ['autopairs']
  elseif has_key(plugins, 'endwise') && exists('g:loaded_endwise')
    call s:remap_endwise()
    let s:endwise = 1
    let all = ['endwise']
  endif
  if has_key(plugins, 'ycm') && exists('g:loaded_youcompleteme')
    call s:remap_ycm()
    let s:ycm = 1
    call add(all, 'ycm')
  endif
  return all
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" auto-pairs, endwise
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun s:remap_autopairs()
  let g:AutoPairsMapBS = 0
  let g:AutoPairsMapCR = 0
  let g:AutoPairsMapCh = 0
  let g:AutoPairsMapSpace = 0
  if s:autopairs_endwise
    call s:ap_ew_cr()
  else
    call s:ap_cr()
  endif
  call s:ap_bs()
  call s:ap_space()
endfun

fun! s:remap_endwise()
  imap <silent> <cr> <plug>(MUcompleteCR-EW)
  imap <silent><expr> <plug>(MUcompleteCR-EW) "\<plug>(MUcompleteCR)\<plug>DiscretionaryEnd"
endfun

fun! s:ap_ew_cr()
  imap <silent> <cr> <plug>(MUcompleteCR-AP-EW)
  imap <silent><expr> <plug>(MUcompleteCR-AP-EW) pumvisible() ?
        \ "\<plug>(MUcompleteCR)\<plug>DiscretionaryEnd" :
        \ "\<plug>(MUcompleteCR)\<plug>DiscretionaryEnd\<c-r>=AutoPairsReturn()\<cr>"
endfun

fun! s:ap_cr()
  imap <silent> <cr> <plug>(MUcompleteCR-AP)
  imap <silent><expr> <plug>(MUcompleteCR-AP) pumvisible() ?
        \ "\<plug>(MUcompleteCR)" :
        \ "\<plug>(MUcompleteCR)\<c-r>=AutoPairsReturn()\<cr>"
endfun

fun! s:ap_bs()
  inoremap <silent> <plug>(MUcompleteBS) <bs>
  imap <silent> <bs> <plug>(MUcompleteBS-AP)
  imap <silent><expr> <plug>(MUcompleteBS-AP) pumvisible() ?
        \ "\<plug>(MUcompleteBS)" : "\<c-r>=AutoPairsDelete()<cr>"
endfun

fun! s:ap_space()
  inoremap <silent> <plug>(MUcompleteSpace) <space>
  imap <silent> <space> <plug>(MUcompleteSpace-AP)
  imap <silent><expr> <plug>(MUcompleteSpace-AP) pumvisible() ?
        \ "\<plug>(MUcompleteSpace)" : "\<c-r>=AutoPairsSpace()<cr>"
endfun

" on first InsertEnter (mapping generation), to ensure the right plug is applied
fun! mucomplete#plugins#cr()
  return
        \s:autopairs_endwise ? "\<plug>(MUcompleteCR-AP-EW)" :
        \s:autopairs         ? "\<plug>(MUcompleteCR-AP)" :
        \s:endwise           ? "\<plug>(MUcompleteCR-EW)" : "\<plug>(MUcompleteCR)"
endfun

" on first InsertEnter (mapping generation), to ensure the right plug is applied
fun! mucomplete#plugins#bs()
  return s:autopairs ? "\<plug>(MUcompleteBS-AP)" : "\<plug>(MUcompleteBS)"
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" YouCompleteMe
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" on first InsertEnter event, an autocommand will be set up, to run on BufEvent
" this will check the filetype and set the i-cspace plug as appropriate


" called on plugin loaded, where it can have an effect
" sets StopCompletion to <c-e> as in MUcomplete
" <tab> and <s-tab> will be handled by MUcomplete only
fun! s:remap_ycm()
  let g:ycm_auto_trigger = 1
  let g:ycm_key_list_stop_completion = ['<c-y>']
  let g:ycm_key_list_previous_completion = ['<Up>']
  let g:ycm_key_list_select_completion = ['<Down>']
endfun

" called when initialized or on BufEnter, to decide the c-space completion
fun! s:use_ycm()
  return
        \ !s:ycm   ? 0 :
        \ g:ycm_filetype_whitelist == {'*': 1} ? 1 :
        \ ( !has_key(g:ycm_filetype_blacklist, &ft) && has_key(g:ycm_filetype_whitelist, &ft) )
endfun

" on first InsertEnter, to initialize ycm plug and set the mapping the first time
fun! mucomplete#plugins#cspace()
  if !s:ycm
    return '<plug>(MUcompleteAlternate)'
  endif
  call s:ycm_au()
  let csp = maparg("<C-Space>", 'i', 0, 1)
  exe 'inoremap <silent> <plug>YcmCSpace <c-r>=<SNR>'.csp['sid'].'_InvokeSemanticCompletion()<cr>'
  imap <silent><expr> <plug>(MUcompleteCSpaceYcm) mucomplete#plugins#ycm_cs()
  return s:use_ycm() ? '<plug>(MUcompleteCSpaceYcm)' : '<plug>(MUcompleteAlternate)'
endfun

" ycm normally uses <c-y> to stop completion, but we're forcing <c-e> for
" consistency. It's also the default vim mapping for this purpose.
" TODO: right now it's using c-y to disable popup and c-e to revert, but I
" couldn't put them toghether
fun! mucomplete#plugins#ce()
  if !s:ycm
    return '<plug>(MUcompletePopupCancel)'
  endif
  call s:ycm_au()
  let csp = maparg("<C-Space>", 'i', 0, 1)
  exe 'inoremap <silent> <plug>YcmCy <c-r>=<SNR>'.csp['sid'].'_StopCompletion( "\<C-Y>" )<cr>'
  imap <silent> <plug>YcmCe <plug>(MUcompletePopupCancel)<plug>YcmCy
  imap <silent><expr> <plug>(MUcompleteCeYcm) mucomplete#plugins#ycm_ce()
  return s:use_ycm() ? '<plug>(MUcompleteCeYcm)' : '<plug>(MUcompletePopupCancel)'
endfun

" called on BufEnter
fun! mucomplete#plugins#ycm_set_maps()
  let m = has('nvim') || has('gui_running') ? "<c-space>" : "<nul>"
  if s:use_ycm()
    exe 'imap <silent>' m '<plug>(MUcompleteCSpaceYcm)'
    exe 'imap <silent> <c-e> <plug>(MUcompleteCeYcm)'
    if exists('#MUcompleteAuto')
      let s:was_auto_enabled = 1
      MUcompleteAutoOff
    endif
  else
    exe 'imap <silent>' m '<plug>(MUcompleteAlternate)'
    exe 'imap <silent> <c-e> <plug>(MUcompletePopupCancel)'
    if s:was_auto_enabled && !exists('#MUcompleteAuto')
      MUcompleteAutoOn
    endif
  endif
endfun

" this is the plug function that is called when cspace is pressed
fun! mucomplete#plugins#ycm_cs()
  return s:use_ycm() ? "\<plug>YcmCSpace" : "\<plug>(MUcompleteAlternate)"
endfun

" this is the plug function that is called when <c-e> is pressed
fun! mucomplete#plugins#ycm_ce()
  return s:use_ycm() ? "\<plug>YcmCe" : "\<plug>(MUcompletePopupCancel)"
endfun

fun! s:ycm_au()
  augroup MUcompleteYcm
    au!
    au BufEnter * call mucomplete#plugins#ycm_set_maps()
  augroup END
endfun
