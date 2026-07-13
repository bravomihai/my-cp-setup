local cp = require("config.cp")
local javac_session = vim.fs.joinpath(vim.fn.stdpath("cache"), "cp-javac", tostring(vim.fn.getpid()))
local javac_run = 0
local javac = vim.env.CP_JAVAC
if not javac or javac == "" then
  javac = "javac"
end

local function remove_directory(path, retries)
  if vim.fn.delete(path, "rf") == 0 or retries == 0 then
    return
  end

  vim.defer_fn(function()
    remove_directory(path, retries - 1)
  end, 100)
end

local function current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function java_path(bufnr)
  local separator = vim.fn.has("win32") == 1 and ";" or ":"
  local source_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  return table.concat({
    cp.path("libraries", "java"),
    cp.path("workspace", "java"),
    source_dir,
  }, separator)
end

local function parse_ruff_syntax(output)
  local diagnostics = {}
  local ok, results = pcall(vim.json.decode, output)
  if not ok then
    return diagnostics
  end

  for _, result in ipairs(results or {}) do
    diagnostics[#diagnostics + 1] = {
      lnum = result.location.row - 1,
      col = result.location.column - 1,
      end_lnum = result.end_location.row - 1,
      end_col = result.end_location.column - 1,
      severity = vim.diagnostic.severity.ERROR,
      message = result.message,
      code = result.code or result.name,
      source = "ruff",
    }
  end

  return diagnostics
end

local function parse_javac(output)
  local diagnostics = {}
  local last

  for line in output:gmatch("[^\r\n]+") do
    local _, lnum, kind, message = line:match("^(.+):(%d+): (error): (.+)$")
    if not lnum then
      _, lnum, kind, message = line:match("^(.+):(%d+): (warning): (.+)$")
    end

    if lnum then
      last = {
        lnum = tonumber(lnum) - 1,
        col = 0,
        severity = kind == "error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
        message = message,
        source = "javac",
      }
      diagnostics[#diagnostics + 1] = last
    elseif last then
      local caret = line:find("^", 1, true)
      if caret then
        last.col = caret - 1
        last = nil
      end
    end
  end

  return diagnostics
end

local function javac_parser(output_dir)
  local chunks = {}

  return {
    on_chunk = function(chunk)
      chunks[#chunks + 1] = chunk
    end,
    on_done = function(publish)
      local output = table.concat(chunks)
      vim.schedule(function()
        publish(parse_javac(output))
        vim.defer_fn(function()
          remove_directory(output_dir, 20)
        end, 100)
      end)
    end,
  }
end

local function javac_linter()
  local bufnr = vim.api.nvim_get_current_buf()
  javac_run = javac_run + 1

  local output_dir = vim.fs.joinpath(javac_session, ("%d-%d"):format(bufnr, javac_run))
  vim.fn.mkdir(output_dir, "p")
  local source = vim.api.nvim_buf_get_name(bufnr)
  local function quoted_path(path)
    return '"' .. path:gsub("\\", "/") .. '"'
  end
  local argfile = vim.fs.joinpath(output_dir, "javac.args")
  vim.fn.writefile({
    "-encoding",
    "UTF-8",
    "-proc:none",
    "-cp",
    quoted_path(java_path(bufnr)),
    "-sourcepath",
    quoted_path(java_path(bufnr)),
    "-d",
    quoted_path(output_dir),
    quoted_path(source),
  }, argfile, "b")

  return {
    cmd = javac,
    stdin = false,
    append_fname = false,
    args = {
      "-J-Duser.language=en",
      "-J-Duser.country=US",
      "@" .. argfile:gsub("\\", "/"),
    },
    ignore_exitcode = true,
    stream = "stderr",
    parser = javac_parser(output_dir),
  }
end

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      remove_directory(javac_session, 0)
      vim.fn.mkdir(javac_session, "p")

      local cleanup_group = vim.api.nvim_create_augroup("cp_javac_cleanup", { clear = true })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = cleanup_group,
        callback = function()
          remove_directory(javac_session, 0)
        end,
      })

      opts.events = { "BufWritePost" }
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.python = { "ruff_syntax" }
      opts.linters_by_ft.java = { "javac_syntax" }

      opts.linters = opts.linters or {}
      opts.linters.ruff_syntax = {
        cmd = "ruff",
        stdin = true,
        args = {
          "check",
          "--no-cache",
          "--force-exclude",
          "--quiet",
          "--select",
          "E9",
          "--stdin-filename",
          current_file,
          "--no-fix",
          "--output-format",
          "json",
          "-",
        },
        ignore_exitcode = true,
        stream = "stdout",
        parser = parse_ruff_syntax,
      }
      opts.linters.javac_syntax = javac_linter
    end,
  },
}
