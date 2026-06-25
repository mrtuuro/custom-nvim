# Neovim Cheatsheet  (leader = Space)

Open this anytime with  <leader>?   ·   close with  q  or  <Esc>
✨ = added recently · others were already in the config

## 🎯 Daily 12 (muscle memory)
  <C-h>/<C-t>/<C-n>  harpoon file 1/2/3        gd                go to definition
  <leader>a          add file to harpoon       K                 hover docs
  <C-p>              find git files            <leader>vca       code action
  <leader>vrn        rename symbol             ]d                next diagnostic
  <leader>gs         git status (fugitive)     <leader>hs/hr     stage/reset hunk
  <leader>pg ✨      live grep                 :GoIfErr ✨       insert if err != nil

## Files & navigation
  <leader>a          harpoon: add current file
  <C-e>              harpoon: menu (reorder / delete)
  <C-h> <C-t> <C-n> <C-s> <C-x>   jump to harpoon file 1..5
  <C-p>              telescope: git files (fastest)
  <leader>pf         telescope: all files
  <leader>pv         Oil file explorer (float)
  <leader>pb ✨      telescope: open buffers
  <leader>pr ✨      telescope: resume last picker

## Search
  <leader>pg ✨      live grep (text across project)
  <leader>lg         multi-grep:  pattern␣␣*.go   (2 spaces = glob filter)
  <leader>ps         grep (prompted)
  <leader>ss         search/replace word under cursor
  <leader>pd ✨      telescope: diagnostics list

## LSP / code intelligence
  gd                 go to definition        gD       go to implementation
  K                  hover info              <leader>vrr   references
  <leader>vrn        rename                  <leader>vca   code action
  <leader>vws        workspace symbol        <leader>f     format buffer
  <leader>vd         line diagnostic float
  ]d / [d ✨         next / prev diagnostic
  <C-h> (insert)     signature help
  (format also runs automatically on :w — goimports + gofumpt)

## Completion & snippets (insert mode)
  <C-n> / <C-p>      next / prev suggestion
  <C-y>              confirm        <C-Space>   trigger completion
  <Tab> / <S-Tab> ✨ jump forward / back inside a snippet

## Git
  <leader>gs         fugitive status (stage / commit)
  ]h / [h            next / prev hunk
  <leader>hp         preview hunk       <leader>hb   blame line
  <leader>hs / hr    stage / reset hunk (works in visual too)
  <leader>hS / hR    stage / reset whole buffer
  <leader>hd         diff this
  <leader>gb         sync branch from origin/master   (custom workflow)
  <leader>gd         sync branch from configured dependency
  :BranchPropagate <src> <dst>   merge src into dst

## Editing power moves
  V then J / K       move selected lines down / up (auto reindent)
  J                  join lines (keep cursor)
  <leader>p (visual) paste WITHOUT clobbering the register
  <leader>y / Y      yank to system clipboard
  <leader>d          delete to black hole (no register)
  <C-d> / <C-u>      half-page down / up (centered)
  n / N              next / prev search (centered)
  sa / sd / sr ✨    surround add / delete / replace (e.g. saiw"  sd"  sr"')
  if / af            textobject: inside / around function (dif, vaf, ...)
  ia / aa            textobject: inside / around parameter
  ]f / [f            jump to next / prev function
  <leader>sn / sp    swap parameter with next / prev

## Diagnostics list (Trouble ✨)
  <leader>xx         workspace diagnostics      <leader>xX   buffer diagnostics
  <leader>xr         LSP references / defs      <leader>xs   symbols
  <leader>xq / xl    quickfix / location list

## Go workflow ✨
  :GoIfErr           insert  if err != nil { return err }
  :GoFillStruct      fill struct literal with all fields
  :GoAddTag json     add struct tags        :GoRmTag   remove
  :GoTestFunc        run test under cursor
  <leader>li         golangci-lint (file) -> quickfix
  <leader>ve         go vet (package)     -> quickfix
  (jump through results with <C-k> / <C-j>)

## Debug (DAP ✨)   needs delve:  go install .../dlv@latest  |  :MasonInstall delve
  <leader>b          toggle breakpoint     <leader>B   conditional breakpoint
  <F5>               start / continue
  <F10> / <F11>      step over / into      <S-F11>     step out
  <F4>               debug nearest Go test (UI opens automatically)
  <F6>               toggle debug UI

## Terminal & quickfix
  <leader>tt         floating terminal (toggle)
  <leader>st         split terminal (bottom)
  <Esc><Esc>         leave terminal mode
  <C-k> / <C-j>      quickfix next / prev (centered)
  <leader>k / j      location list next / prev

## TODO comments ✨
  ]t / [t            next / prev TODO/FIXME      <leader>pt   search all (Telescope)

## Misc
  <leader>X          chmod +x current file
  <leader><leader>   source current file
  <leader>?          open this cheatsheet
