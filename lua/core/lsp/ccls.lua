local lsp = require("core.lsp")

return {
  name = 'ccls',
  cmd = { "ccls" },
  filetypes = { "c", "cpp" },
  root_dir = vim.fs.find({ "compile_commands.json", ".ccls", ".git" }, { upward = true })[1],
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
