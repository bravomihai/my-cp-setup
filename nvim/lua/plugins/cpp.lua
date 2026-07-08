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
        clangd = {},
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