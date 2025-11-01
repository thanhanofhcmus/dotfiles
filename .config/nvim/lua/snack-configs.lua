return {
    animate = {
        enabled = false
    },
    bigfile = {
        enabled = true
    },
    dashboard = {
        enabled = false
    },
    explorer = {
        enabled = true,
        replace_netrw = true,
    },
    indent = {
        enabled = true,
        animate = {
            enabled = false
        },
        scope = {
            enabled = true,
        },
    },
    input = {
        enabled = true
    },
    image = {
        enabled = true
    },
    lazygit = {
        enabled = true
    },
    picker = {
        enabled = true,
        sources = {
            explorer = {
                auto_close = true,
                -- layout = { layout = { position = "right" } },
                layout = {
                    preset = 'telescope',
                    reverse = false,
                },
            },
        },
    },
    notifier = {
        enabled = true,
    },
    quickfile = {
        enabled = true
    },
    scope = {
        enabled = true
    },
    scroll = {
        enabled = false
    },
    statuscolumn = {
        enabled = true
    },
    terminal = {
        enabled = true,
        win = {
            style = 'float',
            border = 'rounded',
            width = math.floor(vim.o.columns * 0.8),
            height = math.floor(vim.o.lines * 0.8),
        }
    },
    toggle = {
        enabled = false
    },
    words = {
        enabled = true
    },
}
