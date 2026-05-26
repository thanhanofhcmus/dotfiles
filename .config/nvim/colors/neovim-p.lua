-- neovim-p.lua
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end
vim.g.colors_name = "neovim-p"

local hl = vim.api.nvim_set_hl

-- GUI/Modern Term: Transparency and soft palette
hl(0, 'Normal', { bg = "none" })
hl(0, 'NormalFloat', { bg = "none" })
hl(0, 'FloatBorder', { bg = "none" })
hl(0, 'Pmenu', { bg = "none" })

hl(0, 'Keyword', { ctermfg = 'yellow', fg = "NvimLightYellow", bold = true })
hl(0, 'SnacksIndentScope', { ctermfg = 'white', fg = "white" })
hl(0, 'SnacksPickerDir', { fg = "NvimLightGrey4" })

-- Add default comments/strings for GUI if not defined elsewhere
hl(0, 'Comment', { fg = "NvimLightGrey3", italic = true })
hl(0, 'String', { ctermfg = 113, fg = "NvimLightGreen" })
