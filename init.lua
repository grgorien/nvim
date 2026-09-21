vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.clipboard = "unnamedplus"

vim.filetype.add({
    extension = {
        tmpl = "gotmpl",
        templ = "templ"
    },
})

vim.api.nvim_create_autocmd({ "BufEnter", "TermEnter", "TermLeave" }, {
    desc = "cd into term:// on enter cwd",
    pattern = "term://*",
    callback = function()
        local cwd = vim.fn.resolve("/proc/" .. vim.b.terminal_job_pid .. "/cwd")
        if vim.fn.isdirectory(cwd) == 0 then return end
        vim.fn.chdir(cwd)
    end,
})

vim.lsp.config("gopls", {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
        gopls = {
            ["build.templateExtensions"] = { "tmpl", "gotmpl" },
            hints = {
                parameterNames = true,
                assignVariables = true,
                constantValues = true,
                rangeVariableTypes = true,
                compositeLiteralFields = true,
                functionTypeParameters = true,
            },
        },
    },
})
vim.lsp.enable("gopls")

vim.lsp.config("templ", {
    cmd = { "templ", "lsp" },
    filetypes = { "templ" },
    root_markers = { "go.mod", ".git" },
})
vim.lsp.enable("templ")

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr })
    end,
})

vim.api.nvim_create_autocmd({ "TermRequest" }, {
    desc = "handles osc 7 dir change req",
    callback = function(ev)
        local pwd, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*", "")
        if n <= 0 then return end
        if vim.fn.isdirectory(pwd) == 0 then return end
        if vim.api.nvim_get_current_buf() ~= ev.buf then return end
        vim.cmd.cd(pwd)
    end
})

-- packages
vim.pack.add({
    { src = "https://github.com/blazkowolf/gruber-darker.nvim", name = "gruber" },
    { src = "https://github.com/ibhagwan/fzf-lua",              name = "fzf-lua" },
})

vim.cmd.colorscheme("gruber-darker")
require("gruber-darker").setup({
    opts = {
        bold = false,
        italic = { strings = false },
    }
})

-- fzf-lua: no setup() needed for defaults, just pull the module
local fzf = require("fzf-lua")
fzf.setup({
    winopts = {
        preview = { layout = "vertical", vertical = "down:45%" },
    },
    -- use fd if available, otherwise find; respects .gitignore
    files = { fd_opts = "--color=never --type f --hidden --follow --exclude .git" },
})

-- keymaps
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")
map("t", "<esc><esc>", "<C-\\><C-n>")

-- navigation
map("n", "<leader>f",  fzf.files,                   { desc = "files" })
map("n", "<leader>b",  fzf.buffers,                  { desc = "buffers" })
map("n", "<leader>g",  fzf.live_grep,                { desc = "grep" })
map("n", "<leader>/",  fzf.grep_curbuf,              { desc = "grep buf" })
-- lsp (only active when a server is attached)
map("n", "<leader>sd", fzf.lsp_document_symbols,     { desc = "doc symbols" })
map("n", "<leader>sw", fzf.lsp_workspace_symbols,    { desc = "workspace symbols" })
map("n", "<leader>sr", fzf.lsp_references,           { desc = "references" })
-- buf cycle
map("n", "]b", "<cmd>bnext<CR>",   { desc = "next buf" })
map("n", "[b", "<cmd>bprev<CR>",   { desc = "prev buf" })
-- close buffer without nuking the window
map("n", "<leader>x", function()
    local listed = vim.fn.getbufinfo({ buflisted = 1 })
    if #listed > 1 then vim.cmd("bprev") end
    vim.cmd("bdelete #")
end, { desc = "close buf" })

-- visual line move
map("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "move sel down" })
map("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "move sel up" })
map("n", "<leader>j", ":m .+1<CR>==", { silent = true, desc = "move line down" })
map("n", "<leader>k", ":m .-2<CR>==", { silent = true, desc = "move line up" })
