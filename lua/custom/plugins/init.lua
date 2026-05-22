-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    url = 'https://git.disroot.org/andyg/leap.nvim.git',
    name = 'leap.nvim',
    config = function()
      local leap = require 'leap'

      vim.keymap.set({ 'n', 'x', 'o' }, '<S-J>', '<Plug>(leap)', { desc = 'Leap' })
      vim.keymap.set({ 'n', 'x', 'o' }, '-', '<Plug>(leap)', { desc = 'Leap' })
      vim.keymap.set('n', '<A-j>', '<Plug>(leap-from-window)', { desc = 'Leap from window' })
      vim.keymap.set('n', '_', '<Plug>(leap-from-window)', { desc = 'Leap from window' })

      vim.keymap.set({ 'n', 'o' }, 'gs', '<Plug>(leap-remote)', { desc = 'Leap remote' })
      vim.keymap.set({ 'n', 'o' }, 'gS', '<Plug>(leap-remote-linewise)', { desc = 'Leap remote linewise' })
      vim.keymap.set({ 'x', 'o' }, 'ar', '<Plug>(leap-remote-text-object)', { desc = 'Leap around remote text object' })
      vim.keymap.set({ 'x', 'o' }, 'ir', '<Plug>(leap-remote-inner-text-object)', { desc = 'Leap inner remote text object' })

      leap.opts.preview = function(ch0, ch1, ch2) return not (ch1:match '%s' or (ch0:match '%a' and ch1:match '%a' and ch2:match '%a')) end
    end,
  },
}
