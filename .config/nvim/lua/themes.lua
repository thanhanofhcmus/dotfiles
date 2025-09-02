require("catppuccin").setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = {     -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = true,
    show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
    term_colors = true,         -- sets terminal colors (e.g. `g:terminal_color_0`)
    dim_inactive = {
        enabled = false,        -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15,      -- percentage of the shade to apply to the inactive window
    },
    no_italic = false,
    no_bold = false,
    no_underline = false,
    styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },
    color_overrides = {
        mocha = {
            base = "#000000",
            mantle = "#000000",
            crust = "#000000",
        },
    },
    custom_highlights = {},
    integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        neotree = true,
        notify = false,
        mini = false,
    },
})

vim.o.winborder = "rounded"

vim.cmd.colorscheme "catppuccin"
