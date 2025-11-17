local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if vim.fn.empty(vim.fn.glob(lazypath)) == 1 then
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

-- Auto-restart after initial plugin install
local first_run_flag = vim.fn.stdpath("data") .. "/.lazy-first-run"
if vim.fn.filereadable(first_run_flag) == 0 then
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyInstall",
    once = true,
    callback = function()
      vim.fn.writefile({}, first_run_flag)
      vim.notify("Plugins installed. Restarting nvim...", vim.log.levels.INFO)
      vim.defer_fn(function()
        vim.cmd("qall")
      end, 2000)
    end,
  })
end
