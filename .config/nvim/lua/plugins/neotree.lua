require('neo-tree').setup({
    filesystem = {
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
        filtered_items = {
            visible = true,
        },
        group_empty_dirs = true,
    },
    window = {
        position = 'right'
    }
})
