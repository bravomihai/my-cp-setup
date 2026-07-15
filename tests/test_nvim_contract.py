import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUTOCMDS = (ROOT / "nvim" / "lua" / "config" / "autocmds.lua").read_text(
    encoding="utf-8"
)
KEYMAPS = (ROOT / "nvim" / "lua" / "config" / "keymaps.lua").read_text(encoding="utf-8")


class NeovimContractTests(unittest.TestCase):
    def test_first_source_buffer_replays_filetype_once_after_lazy_load(self) -> None:
        for token in (
            'vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }',
            "vim.schedule(function()",
            "vim.api.nvim_buf_is_valid(event.buf)",
            "vim.b[event.buf].cp_lsp_filetype_replayed",
            "vim.b[event.buf].cp_lsp_filetype_replayed = true",
            'vim.api.nvim_exec_autocmds("FileType", { buffer = event.buf',
        ):
            self.assertIn(token, AUTOCMDS)

        checked = AUTOCMDS.index("vim.b[event.buf].cp_lsp_filetype_replayed")
        marked = AUTOCMDS.index("vim.b[event.buf].cp_lsp_filetype_replayed = true")
        replayed = AUTOCMDS.index('vim.api.nvim_exec_autocmds("FileType"')
        self.assertLess(checked, marked)
        self.assertLess(marked, replayed)

    def test_project_keeps_one_manual_format_mapping(self) -> None:
        self.assertEqual(KEYMAPS.count('"<leader>cf"'), 1)
        self.assertIn('pcall(require, "conform")', KEYMAPS)
        self.assertIn('lsp_format = "fallback"', KEYMAPS)
        self.assertIn("vim.lsp.buf.format", KEYMAPS)


if __name__ == "__main__":
    unittest.main()
