require('telescope').setup({
    defaults = {
        layout_config = {
            horizontal = { width = 0.9 }
        },
        mappings = {
            -- i = {
            --     ['<C-j>'] = 'move_selection_next',
            --     ['<C-k>'] = 'move_selection_previous'
            -- },
        },
        file_ignore_patterns = { "node_modules", "build*" }
    }
})
