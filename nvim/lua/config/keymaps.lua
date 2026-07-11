-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

-- exit insert
vim.keymap.set("i", "jj", "<Esc>")

local setup_root = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h")
local scripts_dir = setup_root .. "\\scripts\\"
local python = vim.env.CP_PYTHON or "python"
local cp_extensions = { cpp = true, java = true, py = true }

local function current_cp_file()
  local file = vim.fn.expand("%:p")
  local ext = vim.fn.expand("%:e"):lower()

  if file == "" or not cp_extensions[ext] then
    vim.notify("This command supports only .cpp, .java, and .py files", vim.log.levels.WARN)
    return nil
  end

  return file, ext
end

local function expand_for_submission(open_submit)
  local file, ext = current_cp_file()
  if not file then
    return
  end

  vim.cmd("write")
  local expander = scripts_dir .. "expand.py"
  local out = vim.fn.system({ python, expander, file })

  if vim.v.shell_error ~= 0 then
    vim.notify(vim.trim(out), vim.log.levels.ERROR)
    return
  end

  vim.notify(vim.trim(out))

  if open_submit then
    local submit = vim.fn.fnamemodify(file, ":h") .. "\\submit." .. ext
    vim.cmd("edit " .. vim.fn.fnameescape(submit))
  end
end

-- compile & run
vim.keymap.set("n", "<leader>r", function()
  local file = current_cp_file()
  if not file then
    return
  end

  vim.cmd("w")
  local runner = scripts_dir .. "run.py"
  vim.fn.system({ python, runner, "--new-cmd", file })
end, { desc = "Run current file" })

vim.keymap.set("n", "<leader>i", function()
  local file = current_cp_file()
  if not file then
    return
  end

  local debug_dir = vim.fn.fnamemodify(file, ":h") .. "\\debug"
  vim.fn.mkdir(debug_dir, "p")
  vim.cmd("edit " .. vim.fn.fnameescape(debug_dir .. "\\input.txt"))
end, { desc = "Open debug input" })

-- expand for submission
vim.keymap.set("n", "<leader>e", function()
  expand_for_submission(false)
end, { desc = "Expand for submission" })

vim.keymap.set("n", "<leader>E", function()
  expand_for_submission(true)
end, { desc = "Expand and open submission" })

vim.keymap.set("n", "<leader>d", function()
  local enabled = vim.b.cp_diagnostics_enabled
  if enabled == nil then
    enabled = true
  end

  if enabled then
    vim.diagnostic.disable(0)
    vim.b.cp_diagnostics_enabled = false
    vim.notify("Diagnostics disabled")
  else
    vim.diagnostic.enable(0)
    vim.b.cp_diagnostics_enabled = true
    vim.notify("Diagnostics enabled")
  end
end, { desc = "Toggle diagnostics" })

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
