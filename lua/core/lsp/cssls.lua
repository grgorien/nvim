local lsp = require("core.lsp")

return {
  name = 'cssls',
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less", "liquid" },
  settings = {
    css = {
      lint = { unknownAtRules = "ignore" }
    }
  },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
