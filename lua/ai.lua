local M = {}

-- keys 
M.keys = {
    -- copilot ghost text (insert mode)
    copilot_accept = '<C-l>',
    copilot_next   = '<C-j>',
    copilot_prev   = '<C-k>',

    -- toggles / diagnostics (normal mode)
    copilot_toggle = '<leader>tc',
    fim_toggle     = '<leader>tf',
    check          = '<leader>ti',

    -- local FIM; handed to llama.vim as g:llama_config.keymap_fim_*
    fim_trigger     = '<C-f>',
    fim_accept_full = '<Tab>',
    fim_accept_line = '<S-Tab>',
    fim_accept_word = '<C-Right>',
}

-- options 
M.opts = {
    copilot  = true,                     -- copilot inline completion on at startup
    fim_auto = false,                    -- local FIM while typing (false = only on fim_trigger)
    fim_host = 'http://127.0.0.1:8012',  -- must match what llama-server prints at startup
}
-- flip it (and turn copilot off with copilot_toggle) for a fully local session.

local function bind(mode, lhs, rhs, desc)
    if lhs then
        vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end
end

function M.toggle_copilot()
    local on = not vim.lsp.inline_completion.is_enabled()
    vim.lsp.inline_completion.enable(on)
    vim.notify('Copilot inline completion: ' .. (on and 'on' or 'off'))
end

function M.toggle_fim()
    -- command name not confirmed against llama.vim's source; falls back loudly.
    if vim.fn.exists(':LlamaToggle') == 2 then
        vim.cmd('LlamaToggle')
    else
        vim.notify('llama.vim: no :LlamaToggle here, see :help llama', vim.log.levels.WARN)
    end
end

-- use real source buffer (.go/.py/.ts) so the copilot client is attached.
function M.check()
    local lines = {}
    local function add(s) lines[#lines + 1] = s end

    add('copilot-language-server on PATH: '
    .. (vim.fn.executable('copilot-language-server') == 1 and 'yes'
    or 'NO  (npm i -g @github/copilot-language-server)'))
    add('copilot client attached to this buffer: '
    .. (#vim.lsp.get_clients({ name = 'copilot', bufnr = 0 }) > 0 and 'yes' or 'NO'))
    add(':LspCopilotSignIn defined: '
    .. (vim.fn.exists(':LspCopilotSignIn') == 2 and 'yes'
    or 'NO  (nvim-lspconfig copilot config not active here)'))
    add('inline completion enabled: ' .. tostring(vim.lsp.inline_completion.is_enabled()))

    vim.system(
        { 'curl', '-s', '-m', '1', '-o', '/dev/null', '-w', '%{http_code}', M.opts.fim_host .. '/health' },
        { text = true },
        function(r)
            vim.schedule(function()
                local code = vim.trim(r.stdout or '')
                add('llama-server /health: ' .. (code == '200' and 'ok' or ('unreachable (' .. code .. ')')))
                vim.notify(table.concat(lines, '\n'))
            end)
        end
    )
end

function M.setup(user)
    user = user or {}
    M.opts = vim.tbl_deep_extend('force', M.opts, user.opts or {})
    M.keys = vim.tbl_deep_extend('force', M.keys, user.keys or {})
    local o, K = M.opts, M.keys

    -- llama.vim reads g:llama_config when it loads, so set it before vim.pack.add.
    vim.g.llama_config = {
        endpoint_fim           = o.fim_host .. '/infill',
        auto_fim               = o.fim_auto,
        keymap_fim_trigger     = K.fim_trigger,
        keymap_fim_accept_full = K.fim_accept_full,
        keymap_fim_accept_line = K.fim_accept_line,
        keymap_fim_accept_word = K.fim_accept_word,
    }

    vim.pack.add({
        'https://github.com/neovim/nvim-lspconfig',
        'https://github.com/ggml-org/llama.vim',
    })

    vim.lsp.enable('copilot')
    vim.lsp.inline_completion.enable(o.copilot)

    bind('i', K.copilot_accept, vim.lsp.inline_completion.get, 'Copilot: accept suggestion')
    bind('i', K.copilot_next, function() vim.lsp.inline_completion.select({ count = 1 }) end, 'Copilot: next suggestion')
    bind('i', K.copilot_prev, function() vim.lsp.inline_completion.select({ count = -1 }) end, 'Copilot: prev suggestion')
    bind('n', K.copilot_toggle, M.toggle_copilot, 'Toggle Copilot inline completion')
    bind('n', K.fim_toggle, M.toggle_fim, 'Toggle local FIM (llama.vim)')
    bind('n', K.check, M.check, 'AI completion diagnostics')

    vim.api.nvim_create_user_command('AiCheck', M.check, { desc = 'Check Copilot + llama-server status' })
end

return M
