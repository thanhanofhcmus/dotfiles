require('telescope').setup({
    defaults = {
        layout_config = {
            horizontal = { width = 0.9 }
        },
        file_ignore_patterns = { "node_modules", "build*" }
    }
})
