return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        java = { "google-java-format" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "google-java-format",
      })
    end,
  },
}
