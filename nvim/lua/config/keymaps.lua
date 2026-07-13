-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.mapleader = " "

-- exit insert
vim.keymap.set("i", "jj", "<Esc>")

local cp = require("config.cp")
local scripts_dir = cp.path("scripts")
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

local function sibling_file(name, clear)
  local file = vim.fn.expand("%:p")
  local directory = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local path = directory .. "\\" .. name
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  if clear then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
    vim.bo.modified = true
    vim.notify(name .. " cleared (use u to undo)")
    vim.cmd("startinsert")
  end
end

local function run_current(verify)
  local file = current_cp_file()
  if not file then
    return
  end

  vim.cmd("write")
  local arguments = { python, vim.fs.joinpath(scripts_dir, "run.py"), "--new-cmd" }
  if verify then
    table.insert(arguments, "--verify")
  end
  table.insert(arguments, file)
  vim.fn.system(arguments)
end

local function expand_for_submission(open_submit)
  local file, ext = current_cp_file()
  if not file then
    return
  end

  vim.cmd("write")
  local expander = vim.fs.joinpath(scripts_dir, "expand.py")
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
  run_current(false)
end, { desc = "Run current file" })

vim.keymap.set("n", "<leader>i", function()
  sibling_file("input.txt", false)
end, { desc = "Open input" })

vim.keymap.set("n", "<leader>I", function()
  sibling_file("input.txt", true)
end, { desc = "Clear and open input" })

vim.keymap.set("n", "<leader>x", function()
  sibling_file("expected.txt", false)
end, { desc = "Open expected output" })

vim.keymap.set("n", "<leader>X", function()
  sibling_file("expected.txt", true)
end, { desc = "Clear and open expected output" })

vim.keymap.set("n", "<leader>v", function()
  run_current(true)
end, { desc = "Verify output" })

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
    vim.diagnostic.enable(false, { bufnr = 0 })
    vim.b.cp_diagnostics_enabled = false
    vim.notify("Diagnostics disabled")
  else
    vim.diagnostic.enable(true, { bufnr = 0 })
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
  require("conform").format({ async = false, lsp_format = "fallback" })
end, { desc = "Format current buffer" })

-- buffer nav
vim.keymap.set("n", "<leader><leader>", "<C-^>")
vim.keymap.set("n", "<leader>n", ":bnext<CR>")
vim.keymap.set("n", "<leader>p", ":bprev<CR>")
