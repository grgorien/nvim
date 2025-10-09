local lsp = require("core.lsp")

return {
  name = 'ts_ls',
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "typescript", "vue", "liquid" },
  settings = {
    typescript = {
      preferences = { includePackageJsonAutoImports = "off" },
      suggest = { includeCompletionsForModuleExports = true },
    },
    javascript = {
      preferences = { includePackageJsonAutoImports = "off" },
      suggest = { includeCompletionsForModuleExports = true },
    },
  },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
