local M = {}

M.make_capabilities = function()
  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" }
  }
  return capabilities
end

M.on_attach = function(client, bufnr)
  vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })
  vim.notify(client.name .. " attached to buffer " .. bufnr, vim.log.levels.INFO)
end

M.enable = function(name)
  local ok, config = pcall(require, "core.lsp." .. name)
  if not ok then
    vim.notify("Failed to load LSP config: " .. name, vim.log.levels.ERROR)
    return
  end

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

return M
