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
        -- inline type/param hints — aware of functions around 
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        -- manual signature help while typing args — no popup unless you ask
        vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr })

    end,
})

vim.api.nvim_create_autocmd({ "TermRequest" },{
    desc = "handles osc 7 dir change req",
    callback = function(ev)
        local pwd, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*", "")
        if n <= 0 then return end
        if vim.fn.isdirectory(pwd) == 0 then return end
        if vim.api.nvim_get_current_buf() ~= ev.buf then return end
        vim.cmd.cd(pwd)
    end
})


local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")
map("t", "<esc><esc>", "<C-\\><C-n>")

vim.pack.add({
    { src = "https://github.com/blazkowolf/gruber-darker.nvim", name = "gruber" },
})

vim.cmd.colorscheme("gruber-darker")
require("gruber-darker").setup({
    opts = {
        bold = false,
        italic = {
            strings = false,
        },
    }
})

-- Visual mode: move selection up/down with J/K
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Normal mode: move single line with <leader>j/<leader>k (no modifier, no dwm/terminal conflict)
vim.keymap.set("n", "<leader>j", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<leader>k", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
