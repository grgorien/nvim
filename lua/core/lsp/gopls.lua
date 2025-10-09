local lsp = require("core.lsp")

return {
  name = 'gopls',
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = vim.fs.find({ "go.mod", "go.work", ".git" }, { upward = true })[1],
  settings = {},
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
