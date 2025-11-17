local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local first_install = false
if vim.fn.empty(vim.fn.glob(lazypath)) == 1 then
  first_install = true
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.keymap.set("n", "<leader>L", "<cmd>Lazy update<CR>", { desc = "Lazy: Update plugins" })

require("lazy").setup("plugins", {
  defaults = {
    lazy = true,
    version = false,
  },
  install = {
    missing = true,
    colorscheme = { "catppuccin" },
  },
  headless = {
    task = true,
    colors = false,
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      paths = {},
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin"
      },
    },
  },
  ui = {
    border = "rounded",
    backdrop = 60,
  },
  checker = {
    enabled = false,
  },
  change_detection = {
    enabled = false,
  },
  debug = false,
})

-- Auto-quit after initial install
if first_install then
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.notify("First install complete. Exiting in 3 seconds...", vim.log.levels.WARN)
      vim.defer_fn(function()
        vim.cmd("qall!")
      end, 3000)
    end,
  })
end
