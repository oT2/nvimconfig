-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
--vim.diagnostic.config { virtual_lines = { current_line = true } }
-- Exit from insert mode by Esc in Terminal
vim.keymap.set("t", "<esc>", [[<C-\><C-n>]])
vim.opt.shell = "/usr/bin/fish"

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    require("config.ot2header").update_header()
  end,
})
vim.api.nvim_create_user_command("AddHeader", function()
  require("config.ot2header").insert_header()
end, {})
