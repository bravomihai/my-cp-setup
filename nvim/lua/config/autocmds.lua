-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("BufLeave", {
  pattern = { "*.cpp", "*.java", "*.py", "input.txt", "expected.txt" },
  callback = function(event)
    if vim.bo[event.buf].modified then
      vim.api.nvim_buf_call(event.buf, function()
        vim.cmd("write")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "java", "python" },
  callback = function()
    vim.wo.wrap = false
  end,
})

-- LazyVim loads LSP support on the first file event. Replay that buffer's
-- FileType event after the lazy handler finishes so Neovim's capability-aware
-- LSP mappings and client startup also apply to the first source file opened.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp", "*.java", "*.py" },
  callback = function(event)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(event.buf) or vim.b[event.buf].cp_lsp_filetype_replayed then
        return
      end
      vim.b[event.buf].cp_lsp_filetype_replayed = true
      vim.api.nvim_exec_autocmds("FileType", { buffer = event.buf, modeline = false })
    end)
  end,
})

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" },
})
