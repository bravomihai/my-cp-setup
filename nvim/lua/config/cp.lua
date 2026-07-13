local M = {}

local setup_root

local function canonical_path(path)
  local absolute = vim.fn.fnamemodify(path, ":p")
  return (vim.uv or vim.loop).fs_realpath(absolute) or vim.fs.normalize(absolute)
end

function M.setup_root()
  if setup_root then
    return setup_root
  end

  local configured_root = vim.env.CP_SETUP_ROOT
  if not configured_root or configured_root == "" then
    local config_path = canonical_path(vim.fn.stdpath("config"))
    configured_root = vim.fs.dirname(config_path)
  end

  setup_root = canonical_path(configured_root)
  return setup_root
end

function M.path(...)
  return vim.fs.joinpath(M.setup_root(), ...)
end

function M.relative_path(...)
  local path = M.path(...)
  local relative = vim.fs.relpath(M.setup_root(), path)
  assert(relative, ("Could not make %s relative to CP_SETUP_ROOT"):format(path))
  local normalized = relative:gsub("\\", "/")
  return normalized
end

return M
