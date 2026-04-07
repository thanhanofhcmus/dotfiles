-- Standard colorscheme reset logic
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

-- Define theme name
vim.g.colors_name = "neovim-p"

local hl = vim.api.nvim_set_hl
local is_tty = vim.env.TERM == "linux"


-- In TTY, 'none' can sometimes cause flickering; we use 'none' for GUI transparency
local bg_val = is_tty and "none" or "none"

hl(0, 'Normal', { bg = bg_val })
hl(0, 'NormalFloat', { bg = bg_val })
hl(0, 'FloatBorder', { bg = bg_val })
hl(0, 'Pmenu', { bg = bg_val })

-- If in TTY, we use standard ANSI color names. If GUI, we use Nvim palette names.
local keyword_fg = is_tty and "yellow" or "NvimLightYellow"
local grey_fg    = is_tty and "grey" or "NvimLightGrey4"

hl(0, 'Keyword', { fg = keyword_fg, bold = is_tty }) -- Bold in TTY for visibility

hl(0, 'SnacksIndentScope', { fg = "white" })
hl(0, 'SnacksPickerDir', { fg = grey_fg })

if is_tty then
    -- High contrast for raw console
    hl(0, 'Comment', { fg = "cyan", italic = false })
    hl(0, 'String', { fg = "green" })
    hl(0, 'Search', { fg = "black", bg = "yellow" })
end
