return {
  "neovim/nvim-lspconfig",
  optional = true,
  opts = {
    diagnostics = {
      virtual_text = false,
      --      virtual_lines = { current_line = true }
    },
  },
}
