" The variable g:mucomplete#plugin_compatibility is checked.
" Compatibility plugs are generated, but not necessarily assigned.
" Some mappings will be set at mapping generation, others right away.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:autopairs_endwise = 0
let s:autopairs = 0
let s:endwise = 0
let s:ycm = 0
let s:was_auto_enabled = 0
let s:was_bs_enabled = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize/finalize
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This function is called on plugin loaded, where it makes sense to change
" default mappings and settings
fun! mucomplete#plugins#init()
  let all = []
  if s:handled('autopairs') && s:handled('endwise')
    let s:autopairs_endwise = 1
    call s:remap_autopairs()
    let all = ['autopairs', 'endwise']
  elseif s:handled('autopairs')
    let s:autopairs = 1
    call s:remap_autopairs()
    let all = ['autopairs']
  elseif s:handled('endwise')
    call s:remap_endwise()
    let s:endwise = 1
    let all = ['endwise']
  endif
  if s:handled('ycm')
    call s:remap_ycm()
    let s:ycm = 1
    call add(all, 'ycm')
  endif
  return all
endfun

fun! mucomplete#plugins#insert_enter()
  if s:handled('ycm')
    let s:ycm_sid = maparg("<C-Space>", 'i', 0, 1).sid
  endif
endfun

fun! mucomplete#plugins#ready()
  if s:handled('ycm')
    call mucomplete#plugins#ycm_set_maps()
    call s:ycm_au()
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" auto-pairs, endwise
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:remap_autopairs()
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

"-------------------------------------------------------------------------------

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

"-------------------------------------------------------------------------------
" on first InsertEnter (mapping generation), to ensure the right plug is applied

fun! mucomplete#plugins#cr()
  return
        \s:autopairs_endwise ? "\<plug>(MUcompleteCR-AP-EW)" :
        \s:autopairs         ? "\<plug>(MUcompleteCR-AP)" :
        \s:endwise           ? "\<plug>(MUcompleteCR-EW)" : "\<plug>(MUcompleteCR)"
endfun

fun! mucomplete#plugins#bs()
  return s:autopairs ? "\<plug>(MUcompleteBS-AP)" : "\<plug>(MUcompleteBS)"
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" YouCompleteMe
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" on first InsertEnter event, an autocommand will be set up, to run on BufEvent
" this will check the filetype and set the i-cspace plug as appropriate


" called on plugin loaded, where it can have an effect
" <tab> and <s-tab> will be handled by MUcomplete only
fun! s:remap_ycm()
  let g:ycm_auto_trigger = 1
  let g:ycm_key_list_previous_completion = ['<Up>']
  let g:ycm_key_list_select_completion = ['<Down>']
  let s:ycm_cty_map = get(g:, 'ycm_key_list_stop_completion', ['<c-y>'])
endfun

fun! s:ycm_au()
  augroup MUcompleteYcm
    au!
    au BufEnter * call mucomplete#plugins#ycm_set_maps()
  augroup END
endfun

" called on BufEnter, sets (non-local) mappings for the current buffer
fun! mucomplete#plugins#ycm_set_maps()
  let m = has('nvim') || has('gui_running') ? "<c-space>" : "<nul>"
  if s:use_ycm()
    let b:mucomplete_ycm = 1
    exe 'imap <silent>' m '<plug>(MUcompleteCSpaceYcm)'
    if mucomplete#plugins#should_remap_cty()
      let y = s:ycm_cty_map[0]
      exe 'imap <silent>' y '<plug>(MUcompleteCtyYcm)'
    endif
    if exists('#MUcompleteAuto')
      let s:was_auto_enabled = 1
      MUcompleteAutoOff
    endif
    if exists('#MUcompleteBS')
      let s:was_bs_enabled = 1
      autocmd! MUcompleteBS
      augroup! MUcompleteBS
    endif
  else
    exe 'imap <silent>' m '<plug>(MUcompleteAlternate)'
    if mucomplete#plugins#should_remap_cty()
      imap <silent> <c-y> <plug>(MUcompletePopupAccept)
    endif
    if s:was_auto_enabled && !exists('#MUcompleteAuto')
      MUcompleteAutoOn
      let s:was_auto_enabled = 0
    endif
    if s:was_bs_enabled && !exists('#MUcompleteBS')
      call mucomplete#maps#bs_augroup()
      let s:was_bs_enabled = 0
    endif
  endif
endfun

"-------------------------------------------------------------------------------
" <C-SPACE>

" on init
fun! mucomplete#plugins#cspace()
  if !s:ycm
    return '<plug>(MUcompleteAlternate)'
  endif
  return s:ycm_cspace()
endfun

" called when cspace is pressed
fun! mucomplete#plugins#ycm_cspace()
  return has_key(b:, 'mucomplete_ycm') ? "\<plug>YcmCSpace" : "\<plug>(MUcompleteAlternate)"
endfun

" plug
fun! s:ycm_cspace()
  exe 'inoremap <silent> <plug>YcmCSpace <c-r>=<SNR>'.s:ycm_sid.'_InvokeSemanticCompletion()<cr>'
  imap <silent><expr> <plug>(MUcompleteCSpaceYcm) mucomplete#plugins#ycm_cspace()
  return s:use_ycm() ? '<plug>(MUcompleteCSpaceYcm)' : '<plug>(MUcompleteAlternate)'
endfun

"-------------------------------------------------------------------------------
" <C-Y>

" on init
fun! mucomplete#plugins#should_remap_cty()
  return s:ycm && !empty(s:ycm_cty_map)
endfun

fun! mucomplete#plugins#cty()
  if !s:ycm
    return '<plug>(MUcompletePopupAccept)'
  endif
  return s:ycm_cty()
endfun

" called when <c-y> is pressed
fun! mucomplete#plugins#ycm_cty()
  return has_key(b:, 'mucomplete_ycm') ? "\<plug>YcmCty" : "\<plug>(MUcompletePopupAccept)"
endfun

" plug
fun! s:ycm_cty()
  exe 'inoremap <silent> <plug>YcmCty <c-r>=<SNR>'.s:ycm_sid.'_StopCompletion( "\<C-Y>" )<cr>'
  imap <silent><expr> <plug>(MUcompleteCtyYcm) mucomplete#plugins#ycm_cty()
  return s:use_ycm() ? '<plug>(MUcompleteCtyYcm)' : '<plug>(MUcompletePopupAccept)'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:handled(plugin)
  let plugins = get(g:, 'mucomplete#plugin_compatibility', {})
  return a:plugin == 'ycm' ? has_key(plugins, 'ycm') && exists('g:loaded_youcompleteme') :
        \a:plugin == 'endwise' ? has_key(plugins, 'endwise') && exists('g:loaded_endwise') :
        \a:plugin == 'autopairs' ? has_key(plugins, 'autopairs') && exists('g:AutoPairsLoaded') : ''
endfun

fun! s:use_ycm()
  return
        \ !s:ycm   ? 0 :
        \ g:ycm_filetype_whitelist == {'*': 1} ? 1 :
        \ ( !has_key(g:ycm_filetype_blacklist, &ft) && has_key(g:ycm_filetype_whitelist, &ft) )
endfun
