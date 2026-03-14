-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { "neovim/nvim-lspconfig" },
    { "windwp/nvim-autopairs", config = true },

    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
})

vim.cmd("colorscheme habamax")

-- LSP
vim.lsp.enable("clangd")

-- Leader key
vim.g.mapleader = " "

-- compile and run cpp
vim.keymap.set("n", "<leader>r", function()
    vim.cmd("w")

    local file = vim.fn.expand("%:p")

    local cmd = 'build_run_cpp.bat "' .. file .. '"'

    vim.fn.system(cmd)
end)

-- Exit insert mode quickly
vim.keymap.set("i", "jj", "<Esc>")

-- Open init.lua
vim.keymap.set("n", "<F2>", function()
    vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
end)

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Show whitespace
vim.opt.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
}

-- Highlight current line
vim.opt.cursorline = true

--Error Diagnostic
vim.diagnostic.config({
    virtual_text = true,
    float = { border = "rounded" },
})

--code rename
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename)

--code action
vim.keymap.set({"n", "v"}, "<leader>ca", vim.lsp.buf.code_action)

--code format
vim.keymap.set("n", "<leader>cf", function()
    vim.lsp.buf.format({ async = false })
end)

--code suggestions
local cmp = require("cmp")

cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    }),
    sources = {
        { name = "nvim_lsp" },
    },
})

-- Buffer navigation
vim.keymap.set("n", "<leader><leader>", "<C-^>")
vim.keymap.set("n", "<leader>n", ":bnext<CR>")
vim.keymap.set("n", "<leader>p", ":bprev<CR>")

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.cpp", "*.h", "*.hpp", "*.c" },
    callback = function()
        vim.lsp.buf.format({ async = false })
    end,
})

-- LSP navigation
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)

--expand cpp file
vim.keymap.set("n", "<leader>e", function()
    vim.cmd("w")

    local file = vim.fn.expand("%:p")
    local cmd = 'expand_cpp.bat "' .. file .. '"'

    vim.fn.system(cmd)

    vim.notify("submit.cpp generated", vim.log.levels.INFO)
end)

--debug cpp file
vim.keymap.set("n", "<leader>d", function()
    vim.cmd("w")

    local file = vim.fn.expand("%:p")
    local dir = vim.fn.expand("%:p:h")

    local cmd = 'start "" cmd /k "cd /d ' .. dir .. ' && debug_cpp.bat "' .. file .. '"'

    vim.fn.system(cmd)
end)


