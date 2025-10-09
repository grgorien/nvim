local lsp = require("core.lsp")

return {
  name = 'lua_ls',
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = vim.fs.find({ ".luarc.json", ".luarc.jsonc", ".git" }, { upward = true })[1],
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
      telemetry = { enable = false },
    },
  },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
