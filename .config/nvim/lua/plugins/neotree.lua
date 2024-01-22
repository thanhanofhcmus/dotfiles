require('neo-tree').setup({
    filesystem = {
        hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
        use_libuv_file_watcher = true,
        filtered_items = {
            visible = true,
        },
        group_empty_dirs = true,
    },
})
