require('commands')
require('plugins')
require('options')

-- must be load after plugins to
-- get all the plugins objects like telescope, nvim-cmp, ...
require('keymaps')
require('lsp')
require('themes')
