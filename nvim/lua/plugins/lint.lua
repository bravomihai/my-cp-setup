local setup_root = vim.env.CP_SETUP_ROOT or vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h")
local javac_output = vim.fn.stdpath("cache") .. "/cp-javac"

local function current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function java_path()
  local source_dir = vim.fn.fnamemodify(current_file(), ":h")
  return setup_root .. "/libraries/java;" .. source_dir
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

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      vim.fn.mkdir(javac_output, "p")

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
      opts.linters.javac_syntax = {
        cmd = "javac",
        stdin = false,
        append_fname = true,
        args = {
          "-J-Duser.language=en",
          "-J-Duser.country=US",
          "-encoding",
          "UTF-8",
          "-proc:none",
          "-cp",
          java_path,
          "-sourcepath",
          java_path,
          "-d",
          javac_output,
        },
        ignore_exitcode = true,
        stream = "stderr",
        parser = parse_javac,
      }
    end,
  },
}
