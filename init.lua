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

vim.api.nvim_create_autocmd({ "BufEnter", "TermEnter", "TermLeave" }, {
    desc = "cd into term:// on enter cwd",
    pattern = "term://*",
    callback = function()
        local cwd = vim.fn.resolve("/proc/" .. vim.b.terminal_job_pid .. "/cwd")
        if vim.fn.isdirectory(cwd) == 0 then return end
        vim.fn.chdir(cwd)
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
