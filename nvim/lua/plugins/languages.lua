local cp = require("config.cp")
local setup_root = cp.setup_root()
local java_source_paths = {
  cp.relative_path("libraries", "java"),
  cp.relative_path("template", "java"),
  cp.relative_path("workspace", "java"),
}
local jdtls_root = vim.env.CP_SETUP_ROOT
if not jdtls_root or jdtls_root == "" then
  jdtls_root = setup_root
else
  jdtls_root = vim.fn.fnamemodify(jdtls_root, ":p"):gsub("[\\/]+$", "")
end
local jdtls_data =
  vim.fs.joinpath(vim.fn.stdpath("data"), "jdtls-workspaces", "cp-" .. vim.fn.sha256(jdtls_root):sub(1, 16))
local jdtls_cmd = { "jdtls", "-data", jdtls_data }
if vim.env.CP_JAVA and vim.env.CP_JAVA ~= "" then
  jdtls_cmd = { "jdtls", "--java-executable", vim.env.CP_JAVA, "-data", jdtls_data }
end

local function publish_java_diagnostics(err, result, context, config)
  if result and result.diagnostics then
    result.diagnostics = vim.tbl_filter(function(diagnostic)
      return diagnostic.message ~= "This method has a constructor name"
    end, result.diagnostics)
  end

  vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, context, config)
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = {
              disableTaggedHints = true,
            },
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "none",
                },
                extraPaths = { cp.path("libraries", "python") },
                typeCheckingMode = "off",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        jdtls = {
          cmd = jdtls_cmd,
          handlers = {
            ["textDocument/publishDiagnostics"] = publish_java_diagnostics,
          },
          root_dir = function(_, on_dir)
            on_dir(setup_root)
          end,
          settings = {
            java = {
              errors = {
                incompleteClasspath = {
                  severity = "ignore",
                },
              },
              project = {
                sourcePaths = java_source_paths,
              },
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "clangd",
        "google-java-format",
        "jdtls",
        "pyright",
      })
    end,
  },
}
