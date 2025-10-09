local lsp = require("core.lsp")

return {
  name = 'golangci_lint_ls',
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod" },
  root_dir = vim.fs.find({ "go.mod", ".git" }, { upward = true })[1],
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
