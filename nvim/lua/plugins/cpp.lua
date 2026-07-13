local function existing_path(paths)
  local uv = vim.uv or vim.loop
  for _, path in ipairs(paths) do
    if path and path ~= "" and (vim.fn.executable(path) == 1 or uv.fs_stat(path)) then
      return path
    end
  end
end

local gpp = existing_path({
  vim.env.CP_GPP,
  vim.fn.exepath("g++"),
  "C:/msys64/mingw64/bin/g++.exe",
  "C:/msys64/ucrt64/bin/g++.exe",
}) or "g++"

local clangd_path_parts = {
  "C:/msys64/mingw64/bin",
  "C:/msys64/ucrt64/bin",
  vim.env.PATH or "",
}
if gpp ~= "g++" then
  table.insert(clangd_path_parts, 1, vim.fn.fnamemodify(gpp, ":h"))
end
local clangd_path = table.concat(clangd_path_parts, ";")

return {
  -- colorscheme
  {
    "ellisonleao/gruvbox.nvim",
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },

  -- autopairs
  {
    "windwp/nvim-autopairs",
    config = true,
  },

  -- treesitter (adaugi C/C++)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "c",
        "cpp",
      })
    end,
  },

  -- LSP (clangd)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--query-driver=" .. gpp,
          },
          cmd_env = {
            PATH = clangd_path,
          },
        },
      },
    },
  },
}
