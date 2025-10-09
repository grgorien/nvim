local lsp = require("core.lsp")

return {
  name = 'shopify_theme_ls',
  cmd = { "shopify", "theme", "language-server" },
  filetypes = { "liquid" },
  root_dir = vim.fs.find({ ".shopifyignore", ".theme-check.yml", ".theme-check.yaml", "shopify.theme.toml" }, { upward = true })[1],
  settings = {},
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
