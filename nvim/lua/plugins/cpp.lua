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
            "--query-driver=C:/msys64/mingw64/bin/g++.exe,C:/msys64/ucrt64/bin/g++.exe,D:/software/programming/msys2/mingw64/bin/g++.exe,D:/software/programming/msys2/ucrt64/bin/g++.exe",
          },
        },
      },
    },
  },

  -- mason tools
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd",
        "clang-format",
      },
    },
  },
}
