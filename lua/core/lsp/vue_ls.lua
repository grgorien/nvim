local lsp = require("core.lsp")
return {
  name = "vue_ls",
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  root_markers = { "package.json" },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
