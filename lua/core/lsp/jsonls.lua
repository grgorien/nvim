local lsp = require("core.lsp")

return {
  name = 'jsonls',
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
