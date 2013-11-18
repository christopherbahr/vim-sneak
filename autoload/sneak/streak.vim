" TODO:
"   janus
"   spf13
"   VIM
"   YADR https://github.com/skwp/dotfiles
" 
" YADR easymotion settings:
"   https://github.com/skwp/dotfiles/blob/master/vim/settings/easymotion.vim
"
" NOTE: cchar cannot be more than 1 character.
"   strategy: make SneakPluginTarget fg/bg the same color, then conceal the
"             other char.
" 
" NOTE: syntax highlighting seems to almost always take priority over 
" conceal highlighting.
"   strategy:
"       syntax clear
"       [do the conceal]
"       syntax enable
" FEATURES:
"   - skips folds
"   - if first match is past window, does not invoke streak-mode
"
" :help :syn-priority
"   In case more than one item matches at the same position, the one that was
"   defined LAST wins.  Thus you can override previously defined syntax items by
"   using an item that matches the same text.  But a keyword always goes before a
"   match or region.  And a keyword with matching case always goes before a
"   keyword with ignoring case.
"
" important options:
"   set concealcursor=ncv
"   set conceallevel=2
"
"   syntax match SneakPluginTarget "e\%20l\%>10c\%<60c" conceal cchar=E
"
"   "conceal match 'e' on line 18 between columns 10,60
"   syntax match Foo4 "e\%18l\%>10c\%<60c" conceal cchar=E

func! ProfileFoo()
  profile start profile.log
  profile func Foo*
  autocmd VimLeavePre * profile pause
endf

"TODO: <space> should skip to the 53rd match, if any
let s:matchkeys = "asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM"
let s:matchmap = {}

func! s:placematch(c, pos)
  let s:matchmap[a:c] = a:pos
  "TODO: figure out why we must +1 the column...
  exec "syntax match SneakConceal '.\\%".a:pos[0]."l\\%".(a:pos[1]+1)."v' conceal cchar=".a:c
endf

"TODO: may need to deal with 'offset' for getpos()/cursor() if virtualedit=all
"NOTE: the search should be 'warm' before profiling
"NOTE: searchpos() appears to be about 30% faster than 'norm! n' for
"      a 1-char search pattern, but needs to be tested on complicated search patterns vs 'norm! /'
func! sneak#streak#to(s)
  call s:init()
  let maxmarks = len(s:matchkeys) - 1
  let w = winsaveview()

  let i = 0
  while i < maxmarks
    " searchpos() is faster than "norm! /m\<cr>", see profile.3.log
    let p = searchpos(a:s, 'W')

    if 0 == max(p)
      break
    endif

    "optimization: if we are in a fold, skip to the end of the fold.
    let foldend = foldclosedend(p[0])
    if -1 != foldend
      if foldend >= line("w$")
        break "fold ends at/below bottom of window.
      endif
      call cursor(foldend + 1, 1)
      continue
    endif

    let c = strpart(s:matchkeys, i, 1)
    call s:placematch(c, p)
    let i += 1
  endwhile

  call winrestview(w)
  redraw

  let choice = sneak#util#getchar()
  if choice != "\<Esc>" && has_key(s:matchmap, choice) "user can press _any_ invalid key to escape.
    let p = s:matchmap[choice]
    call cursor(p[0], p[1])
  endif

  call s:finish()
endf

func! s:finish()
  silent! syntax clear SneakConceal
  call sneak#hl#removehl()
  let &syntax=s:syntax_orig
endf

func! s:init()
  " does not affect search()/searchpos()
  " set foldopen-=search

  set concealcursor=ncv
  set conceallevel=2
  "TODO: restore user's Conceal highlight
  "   https://github.com/osyo-manga/vim-over/blob/d8819448fc4074342abd5cb6cb2f0fff47b7aa22/autoload/over/command_line.vim#L225
  "     redir => conceal_hl
  "     silent highlight Conceal
  "     redir END
  "     let s:old_hi_cursor = substitute(matchstr(conceal_hl, 'xxx \zs.*'), '[ \t\n]\+', ' ', 'g')
  "syntax clear

  let s:syntax_orig=&syntax
  setlocal syntax=OFF

  hi Conceal guibg=magenta guifg=white
endf
