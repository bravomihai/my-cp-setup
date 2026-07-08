-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

-- exit insert
vim.keymap.set("i", "jj", "<Esc>")

local setup_root = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h")
local scripts_dir = setup_root .. "\\scripts\\"
local python = vim.env.CP_PYTHON or "python"

-- compile & run
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("w")
  local file = vim.fn.expand("%:p")
  local runner = scripts_dir .. "run.py"
  vim.fn.system({ python, runner, "--new-cmd", file })
end, { desc = "Run current file" })

-- expand for submission
vim.keymap.set("n", "<leader>e", function()
  vim.cmd("w")
  local file = vim.fn.expand("%:p")
  local ext = vim.fn.expand("%:e")

  if ext ~= "cpp" and ext ~= "java" and ext ~= "py" then
    vim.notify("Expand supports only .cpp, .java, and .py files", vim.log.levels.WARN)
    return
  end

  local expander = scripts_dir .. "expand.py"
  local out = vim.fn.system({ python, expander, file })

  if vim.v.shell_error ~= 0 then
    vim.notify(vim.trim(out), vim.log.levels.ERROR)
    return
  end

  vim.notify(vim.trim(out))
end, { desc = "Expand for submission" })

-- LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "K", vim.lsp.buf.hover)

vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename)
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)

vim.keymap.set("n", "<leader>cf", function()
    vim.lsp.buf.format({ async = false })
end)

-- buffer nav
vim.keymap.set("n", "<leader><leader>", "<C-^>")
vim.keymap.set("n", "<leader>n", ":bnext<CR>")
vim.keymap.set("n", "<leader>p", ":bprev<CR>")
