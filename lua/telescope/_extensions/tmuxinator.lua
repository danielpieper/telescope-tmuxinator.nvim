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

local function tmux_session_lookup()
  local output = utils.get_os_command_output({ 'tmux', 'list-sessions', '-F #S' })

  local t = {}
  for _, v in ipairs(output) do
    for item in string.gmatch(v, "([^%s]+)") do
      t[item] = true
    end
  end

  return t
end

local function get_tmuxinator_projects()
  local sessions = tmux_session_lookup()

  local output = utils.get_os_command_output({ 'tmuxinator', 'list' })
  local t = {}
  for _, v in ipairs(output) do
    -- strip title:
    v = string.gsub(v, "tmuxinator projects:", "")
    for item in string.gmatch(v, "([^%s]+)") do
      table.insert(t, {
        name = item,
        active = sessions[item],
      })
    end
  end

  return t
end

local entry_maker = function(entry)
  local display = entry.name
  if entry.active then
    display = entry.name .. " (active)"
  end
  return {
    value = entry.name,
    display = display,
    ordinal = entry.name,
    active = entry.active,
    -- preview_command = function(entry, bufnr)
    --   local output = vim.split(vim.inspect(entry.value), '\n')
    --   vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, output)
    -- end
  }
end


local projects = function(opts)
  opts = opts or {}

  local results = get_tmuxinator_projects();

  pickers.new(opts, {
    prompt_title = 'Tmuxinator Projects',
    finder = finders.new_table{
      results = results,
      entry_maker = entry_maker,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local selection = actions.get_selected_entry(prompt_bufnr)
        actions.close(prompt_bufnr)
        os.execute('tmuxinator ' .. selection.value)
      end)
      map('i', '<C-x>', function(prompt_bufnr)
        local selection = actions.get_selected_entry(prompt_bufnr)
        actions.close(prompt_bufnr)

        if not selection.active then
          error(selection.value .. " is not active")
          return
        end

        os.execute('tmuxinator stop ' .. selection.value)
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
