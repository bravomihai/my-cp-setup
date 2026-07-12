local setup_root = vim.env.CP_SETUP_ROOT or vim.fn.fnamemodify(vim.fn.stdpath("config"), ":h")

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
                extraPaths = { setup_root .. "/libraries/python" },
                typeCheckingMode = "off",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        jdtls = {
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
                sourcePaths = {
                  "libraries/java",
                  "template/java",
                },
              },
            },
          },
        },
      },
    },
  },
}
