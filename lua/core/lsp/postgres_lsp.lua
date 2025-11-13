print("lsp postgres sql")
local lsp = require("core.lsp")
print(lsp)

return {
  name = "postgres_lsp",
  cmd = { "postgres-language-server", "lsp-proxy" },
  filetypes = { "sql" },
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
