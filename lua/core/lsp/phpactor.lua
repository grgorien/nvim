local lsp = require("core.lsp")

return {
  name = 'phpactor',
  cmd = { "phpactor", "language-server" },
  filetypes = { "php" },
  root_dir = vim.fs.find({ "composer.json", ".git" }, { upward = true })[1],
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
