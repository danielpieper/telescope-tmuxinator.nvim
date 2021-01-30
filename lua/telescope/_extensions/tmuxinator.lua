local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local has_tmux = (vim.fn.executable('tmux') == 1)
if not has_tmux then
  error('This plugin requires tmux.')
end

local has_tmuxinator = (vim.fn.executable('tmuxinator') == 1)
if not has_tmuxinator then
  error('This plugin requires tmuxinator.')
end

local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local utils = require('telescope.utils')

local projects = function(opts)
  opts = opts or {}

  local output = utils.get_os_command_output({ 'tmuxinator', 'list' })
  local results = {}
  for _, v in ipairs(output) do
    -- strip title:
    v = string.gsub(v, "tmuxinator projects:", "")
    for item in string.gmatch(v, "([^%s]+)") do
      table.insert(results, item)
    end
  end

  pickers.new(opts, {
    prompt_title = 'Tmuxinator Projects',
    finder = finders.new_table(results),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local selection = actions.get_selected_entry(prompt_bufnr)
        actions.close(prompt_bufnr)
        os.execute('tmuxinator ' .. selection.value)
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension {
  exports = {
    projects = projects,
  }
}
