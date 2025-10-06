vim.diagnostic.config({
    virtual_text = { current_line = true },
    float = { source = true },
})

local cmp = require('cmp')

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
        { name = 'nvim_lsp_signature_help' },
    },
    snippet = {
        expand = function(args)
            vim.snippet.expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true })
    }),
    -- remember to set vim.o.winborder = "rounded"
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
})

cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
})

cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources(
        { { name = 'path' } },
        { { name = 'cmdline', option = { ignore_cmds = { 'Man', '!' } } } }
    )
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

local servers = {
    'clangd',
    'rust_analyzer',
    'gopls',
    'golangci_lint_ls',
    'zls',
    'yamlls',
    -- 'terraform_lsp', -- don't use this
    -- 'terraformls'
}

for _, lsp in ipairs(servers) do
    vim.lsp.config(lsp, { capabilities = capabilities, })
    vim.lsp.enable(lsp)
end

vim.lsp.config('lua_ls', {
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.enable('lua_ls')

-- Formatting

local function auto_format_callback()
    local filetypes = { "lua", "c", "cpp", "go", "zig" }
    local function is_lsp_supports_fomatting(client)
        return client.supports_method('textDocument/formatting')
    end

    if not vim.tbl_contains(filetypes, vim.bo.filetype) then
        return
    end

    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
        if is_lsp_supports_fomatting(client) then
            vim.lsp.buf.format({ async = false })
        end
    end
end

vim.api.nvim_create_autocmd('BufWritePre', {
    callback = auto_format_callback,
})
