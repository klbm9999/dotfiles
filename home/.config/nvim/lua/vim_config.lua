local o = vim.opt
vim.g.mapleader = ' '		-- space is the leader key
o.expandtab = true		-- spaces, not tabs
o.shiftwidth = 2		-- 2 spaces per indent level
o.number = true			-- absolute number on the cursor line, relative elsewhere
o.relativenumber = true		-- relative line numbers for fast jumps
o.ignorecase = true		-- search is case-insentitive by default
o.smartcase = true		-- case-sensitive only if a capital is typed
o.clipboard = 'unnamedplus'	-- share the system clipboard
-- Over SSH there is no local clipboard tool, so copy through the terminal with
-- OSC 52 (wezterm puts it on the laptop's clipboard). Terminals rarely allow
-- reading the clipboard back, so paste from Neovim's own register instead and
-- use the terminal's paste shortcut for text copied elsewhere.
if os.getenv('SSH_TTY') then
  local osc52 = require('vim.ui.clipboard.osc52')
  local function paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
  end
  vim.g.clipboard = {
    name = 'OSC 52 (copy only)',
    copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end
o.scrolloff = 16		-- keep cursor away from screenedge
o.undofile = true		-- persistent undo across sessions
