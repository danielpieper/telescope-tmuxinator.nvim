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
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local utils = require('telescope.utils')

local state = {
  select_action = nil,
  stop_action = nil,
  disable_icons = false,
}

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

    local disable_icons = opts.disable_icons == nil and state.disable_icons or opts.disable_icons

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

local function set_config_state(opt_name, value, default)
  state[opt_name] = value == nil and default or value
end

local projects = function(opts)
  opts = opts or {}

  opts.entry_maker = opts.entry_maker or entry_maker_gen_from_active_sessions(opts)

  local results = get_tmuxinator_projects();

  local function tmux_current_session()
    local output = utils.get_os_command_output({ 'tmux', 'list-sessions', '-F #{session_attached} #S' })

    for _, v in ipairs(output) do
      for item in string.gmatch(v, "1%s([^%s]+)") do
        return item
      end
    end

    return nil
  end

  pickers.new(opts, {
    prompt_title = 'Tmuxinator Projects',
    finder = finders.new_table{
      results = results,
      entry_maker = opts.entry_maker,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function()
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local current = tmux_current_session()
        actions.close(prompt_bufnr)
        os.execute('tmuxinator ' .. selection.value)
        if state.select_action == 'kill' and current ~= nil then
          os.execute('tmux kill-session -t ' .. current)
        elseif state.select_action == 'stop' and current ~= nil then
          os.execute('tmuxinator stop ' .. current)
        end
      end)

      actions.select_horizontal:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if state.stop_action == 'kill' then
          os.execute('tmux kill-session -t ' .. selection.value)
        else
          os.execute('tmuxinator stop ' .. selection.value)
        end
      end)

      -- no vertical selection here:
      actions.select_vertical:replace(function()
      end)

      -- no multi selection here:
      actions.toggle_selection:replace(function()
      end)

      return true
    end,
  }):find()
end

return telescope.register_extension {
  setup = function(ext_config)
    set_config_state("select_action", ext_config.select_action, 'switch')
    set_config_state("stop_action", ext_config.stop_action, 'stop')
    set_config_state("disable_icons", ext_config.disable_icons, false)
  end,
  exports = {
    projects = projects,
  }
}
