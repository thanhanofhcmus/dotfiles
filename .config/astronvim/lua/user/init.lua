-- local is_available = require('astronvim.utils').is_available

return {
  options = {
    opt = {
      showtabline = 0,

      relativenumber = false,
      number = true,
      spell = true,
      spelloptions = "camel",
      clipboard = "",
      cmdheight = 1,
    }
  },
  colorscheme = "astrotheme",
  --colorscheme = "default",
  mappings = {
    n = {
      ["<leader>b"] = false,
      ["<leader>bb"] = false,
      ["<leader>bd"] = false,
      ["<leader>b\\"] = false,
      ["<leader>b|"] = false,

      ["<C-h>"] = false,
      ["<C-j>"] = false,
      ["<C-k>"] = false,
      ["<C-l>"] = false,
      ["<leader>w"] = false,
    },
  },
  lsp = {
    mappings = {
      n = {
        gh = { function() vim.lsp.buf.hover() end, desc = "Hover symbol details" },
        gj = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" },
        ["<leader>q"] = { function() require("astronvim.utils.buffer").close() end, desc = "Close buffer" },
      }
    }
  },
  polish = function ()
    vim.api.nvim_create_autocmd({ "FileType" }, {
      callback = function()
        vim.opt.formatoptions:remove('c')
        vim.opt.formatoptions:remove('r')
        vim.opt.formatoptions:remove('o')
      end,
    })
    -- TODO: fix this
    -- vim.api.nvim_create_augroup("bigscreeninfo", { clear = true })
    -- vim.api.nvim_create_autocmd({ "BufEnter"}, {
    --   desc = "Open neo-tree and Symbol outline when screen is big",
    --   group = "bigscreeninfo",
    --   callback = function()
    --     local has_aerial = is_available "aerial.nvim"
    --     local has_lps = vim.inspect(next(vim.lsp.get_active_clients())) ~= nil
    --     local big_screen = vim.api.nvim_win_get_width(0) > 100
    --     local cur_buf = vim.api.nvim_get_current_win()
    --
    --     if has_aerial and has_lps and big_screen then
    --       require('aerial').toggle()
    --       vim.api.nvim_set_current_win(cur_buf)
    --     end
    --   end
    -- })
  end,
  plugins = {
    {
      "rebelot/heirline.nvim",
      opts = function(_, opts)
        opts.tabline = nil -- remove tabline
        return opts
      end,
    },
    {
      "kylechui/nvim-surround",
      tag = "v2.1.0",
      lazy = false,
      config = function()
        require("nvim-surround").setup({ })
      end,
    },
  },
}
