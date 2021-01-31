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

local function get_tmuxinator_projects()
  local output = utils.get_os_command_output({ 'tmuxinator', 'list' })
  local t = {}
  for _, v in ipairs(output) do
    -- strip title:
    v = string.gsub(v, "tmuxinator projects:", "")
    for item in string.gmatch(v, "([^%s]+)") do
      table.insert(t, item)
    end
  end

  return t
end

local entry_maker_gen_from_active_sessions
do
  local lookup_keys = {
    ordinal = 1,
    value = 1,
  }

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

  function entry_maker_gen_from_active_sessions(opts)
    opts = opts or {}

    local disable_icons = opts.disable_icons

    local sessions = tmux_session_lookup()
    local mt_file_entry = {}

    if disable_icons then
      mt_file_entry.display = function(entry)
        if sessions[entry.value] then
          return entry.value .. " (active)"
        end
        return entry.value
      end
    else
      mt_file_entry.display = function(entry)
        if sessions[entry.value] then
          return "🟢 " .. entry.value
        end
        return "🔵 " .. entry.value
      end
    end

    mt_file_entry.__index = function(t, k)
      local raw = rawget(mt_file_entry, k)
      if raw then return raw end

      return rawget(t, rawget(lookup_keys, k))
    end

    return function(line)
      return setmetatable({line}, mt_file_entry)
    end
  end
end

local projects = function(opts)
  opts = opts or {}

  opts.entry_maker = opts.entry_maker or entry_maker_gen_from_active_sessions(opts)

  local results = get_tmuxinator_projects();

  pickers.new(opts, {
    prompt_title = 'Tmuxinator Projects',
    finder = finders.new_table{
      results = results,
      entry_maker = opts.entry_maker,
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
