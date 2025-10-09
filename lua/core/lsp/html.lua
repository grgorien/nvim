local lsp = require("core.lsp")

return {
  name = 'html',
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html", "liquid" },
  init_options = {
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = { css = true, javascript = true },
    provideFormatter = false,
  },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
