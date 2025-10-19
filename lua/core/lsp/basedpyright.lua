local lsp = require("core.lsp")
return {
  name = 'basedpyright',
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = vim.fs.dirname(vim.fs.find({ "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" }, { upward = true })[1]),
  settings = {},
  capabilities = lsp.make_capabilities(),
  on_attach = lsp.on_attach,
}
