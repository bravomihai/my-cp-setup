-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- auto format
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.cpp", "*.h", "*.hpp", "*.c", "*.py", "*.java" },
    callback = function()
        if vim.bo.filetype == "python" or vim.bo.filetype == "java" then
            local ok, conform = pcall(require, "conform")
            if ok then
                conform.format({ async = false })
            end
        else
            vim.lsp.buf.format({ async = false })
        end
    end,
})

vim.api.nvim_create_autocmd("BufLeave", {
    callback = function()
        if vim.bo.modified then
            vim.cmd("write")
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "java", "python" },
    callback = function()
        vim.wo.wrap = false
    end,
})

vim.diagnostic.config({
    virtual_text = true,
    float = { border = "rounded" },
})
