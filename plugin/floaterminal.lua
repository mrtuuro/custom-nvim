local ok, service_config = pcall(require, "config.services")
if not ok then
  service_config = {}
end

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
  services = {},
  dashboard = {
    buf = -1,
    win = -1,
    timer = nil,
  },
  return_to_dashboard = false,
  status_override = {},
}

-- Forward declaration; defined later after dashboard helpers.
local open_dashboard

local float_opts = vim.tbl_deep_extend("force", {
  width = 0.8,
  height = 0.8,
  border = "rounded",
}, service_config.float or {})

local services = service_config.services or {}

-- Stable ordering for services so dashboard and iteration are predictable.
local service_order = vim.tbl_keys(services)
table.sort(service_order)

local function resolve_size(value, total)
  if type(value) == "number" and value > 0 and value < 1 then
    return math.floor(total * value)
  end

  return math.floor(value)
end

local function open_floating_win(opts)
  opts = opts or {}

  local width = resolve_size(opts.width or float_opts.width, vim.o.columns)
  local height = resolve_size(opts.height or float_opts.height, vim.o.lines)

  width = math.max(width, 20)
  height = math.max(height, 8)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf
  if vim.api.nvim_buf_is_valid(opts.buf or -1) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = opts.border or float_opts.border,
  }

  if opts.title then
    win_config.title = opts.title
    win_config.title_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

local function is_job_running(job_id)
  if not job_id or job_id <= 0 then
    return false
  end

  local ok_wait, result = pcall(vim.fn.jobwait, { job_id }, 0)
  if not ok_wait then
    return false
  end

  return result[1] == -1
end

--- Fetch all running Docker container names in one call.
--- Returns a set (table mapping container name -> true).
local function get_running_containers()
  local result = vim.system(
    { "docker", "ps", "--format", "{{.Names}}" },
    { text = true }
  ):wait()

  local set = {}
  if result.code == 0 and result.stdout then
    for line in result.stdout:gmatch("[^\r\n]+") do
      local name = vim.trim(line)
      if name ~= "" then
        set[name] = true
      end
    end
  end

  return set
end

--- Check if a Docker container is running by name.
--- Accepts an optional pre-fetched container set to avoid extra calls.
local function is_container_running(container_name, running_set)
  if not container_name then
    return false
  end

  if running_set then
    return running_set[container_name] == true
  end

  local result = vim.system(
    { "docker", "inspect", "-f", "{{.State.Running}}", container_name },
    { text = true }
  ):wait()

  return result.code == 0
    and vim.trim(result.stdout or "") == "true"
end

--- Determine if a service is active (terminal job alive OR container running).
--- Accepts an optional pre-fetched running_set to batch Docker checks.
local function is_service_active(name, running_set)
  local service = state.services[name]
  if service and is_job_running(service.job_id) then
    return true
  end

  local spec = services[name]
  if spec and spec.container then
    return is_container_running(spec.container, running_set)
  end

  return false
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Floaterminal" })
end

--- Run a stop command synchronously so callers can wait for it to finish.
local function run_stop_cmd(cmd, cwd)
  if not cmd then
    return
  end

  vim.system(
    { "bash", "-c", cmd },
    { cwd = cwd, text = true }
  ):wait()
end

local function toggle_terminal()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = open_floating_win({ buf = state.floating.buf })
    if vim.bo[state.floating.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
    return
  end

  vim.api.nvim_win_hide(state.floating.win)
end

local function get_service(name)
  local entry = state.services[name]
  if entry then
    return entry
  end

  entry = {
    name = name,
    buf = -1,
    win = -1,
    job_id = nil,
    started_at = nil,
  }
  state.services[name] = entry

  return entry
end

--- Return true when the buffer can host a new termopen call.
local function is_buf_ready_for_terminal(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if vim.bo[buf].buftype == "terminal" then
    return false
  end

  return true
end

--- Ensure the service has a fresh, usable buffer.
local function ensure_fresh_buf(service)
  if is_buf_ready_for_terminal(service.buf) then
    return service.buf
  end

  if vim.api.nvim_buf_is_valid(service.buf) then
    if vim.api.nvim_win_is_valid(service.win) then
      vim.api.nvim_win_hide(service.win)
      service.win = -1
    end
    pcall(vim.api.nvim_buf_delete, service.buf, { force = true })
  end

  service.buf = vim.api.nvim_create_buf(false, true)
  return service.buf
end

local function open_service(name)
  if not services[name] then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return nil
  end

  local service = get_service(name)

  -- Window already visible -- just focus it.
  if vim.api.nvim_win_is_valid(service.win) then
    vim.api.nvim_set_current_win(service.win)
    return service
  end

  -- If the buffer is a live terminal, reuse it as-is (view logs).
  -- Only create a fresh buffer when there is no valid buffer at all.
  if not vim.api.nvim_buf_is_valid(service.buf) then
    service.buf = vim.api.nvim_create_buf(false, true)
  end

  local opened = open_floating_win({
    buf = service.buf,
    title = " " .. name .. " ",
  })
  service.buf = opened.buf
  service.win = opened.win

  -- Scroll to the bottom so the latest logs are visible.
  local line_count = vim.api.nvim_buf_line_count(service.buf)
  if line_count > 0 then
    pcall(vim.api.nvim_win_set_cursor, service.win, { line_count, 0 })
  end

  local function back_to_dashboard()
    if vim.api.nvim_win_is_valid(service.win) then
      vim.api.nvim_win_hide(service.win)
    end
    if state.return_to_dashboard and open_dashboard then
      state.return_to_dashboard = false
      open_dashboard()
    end
  end

  local map_opts = { buffer = service.buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", back_to_dashboard, map_opts)
  vim.keymap.set("n", "<Esc>", back_to_dashboard, map_opts)

  return service
end

--- Safely kill a running terminal job.
local function kill_job(job_id)
  if not job_id or job_id <= 0 then
    return
  end

  pcall(vim.fn.chansend, job_id, "\003")

  local ok_wait, result = pcall(vim.fn.jobwait, { job_id }, 500)
  if ok_wait and result[1] == -1 then
    pcall(vim.fn.jobstop, job_id)
    pcall(vim.fn.jobwait, { job_id }, 300)
  end
end

--- Full stop: kill terminal job + stop Docker container synchronously.
local function full_stop_service(name)
  local spec = services[name]
  if not spec then
    return
  end

  local service = state.services[name]

  -- 1. Kill the terminal job if it's alive.
  if service and is_job_running(service.job_id) then
    kill_job(service.job_id)
    service.job_id = nil
    service.started_at = nil
  end

  -- 2. Hide the float window.
  if service and vim.api.nvim_win_is_valid(service.win) then
    vim.api.nvim_win_hide(service.win)
  end

  -- 3. Always run the stop command for Docker services to ensure the
  --    container is actually stopped, even if the terminal job died.
  if spec.stop_cmd then
    run_stop_cmd(spec.stop_cmd, spec.cwd)
  end
end

local function start_service(name)
  local spec = services[name]
  if not spec then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return
  end

  local service = get_service(name)

  if is_service_active(name) then
    open_service(name)
    notify(string.format("%s is already running", name))
    return
  end

  -- Prepare a fresh buffer before opening, since termopen requires a
  -- non-terminal buffer.
  ensure_fresh_buf(service)

  local svc = open_service(name)
  if not svc then
    return
  end

  local cmd = spec.cmd
  if type(cmd) ~= "string" and type(cmd) ~= "table" then
    notify(string.format("Service '%s' has invalid cmd", name), vim.log.levels.ERROR)
    return
  end

  service.job_id = vim.fn.termopen(cmd, {
    cwd = spec.cwd,
    on_exit = function()
      service.job_id = nil
      -- Keep started_at for Docker services whose container may still
      -- be running even after the terminal job exits.
      if not spec.container or not is_container_running(spec.container) then
        service.started_at = nil
      end
    end,
  })

  vim.bo[service.buf].buflisted = false
  vim.bo[service.buf].filetype = "floaterminal_service"

  if not is_job_running(service.job_id) then
    notify(string.format("Failed to start %s", name), vim.log.levels.ERROR)
    return
  end

  service.started_at = os.time()
  notify(string.format("Started %s", name))
end

local function stop_service(name)
  local spec = services[name]
  if not spec then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return
  end

  full_stop_service(name)
  notify(string.format("Stopped %s", name))
end

local function restart_service(name)
  full_stop_service(name)
  start_service(name)
end

local function toggle_service(name)
  if not services[name] then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return
  end

  local service = get_service(name)
  if vim.api.nvim_win_is_valid(service.win) then
    vim.api.nvim_win_hide(service.win)
    return
  end

  if is_service_active(name) then
    open_service(name)
    return
  end

  start_service(name)
end

--- View a service's log buffer if it exists, otherwise notify.
local function view_service_logs(name)
  local service = get_service(name)
  if vim.api.nvim_buf_is_valid(service.buf) then
    open_service(name)
  else
    notify(
      string.format("%s has no log buffer (not started yet)", name),
      vim.log.levels.WARN
    )
  end
end

-- ---------------------------------------------------------------------------
-- Uptime helper
-- ---------------------------------------------------------------------------

local function format_uptime(started_at)
  if not started_at then
    return "-"
  end

  local elapsed = os.time() - started_at
  if elapsed < 60 then
    return string.format("%ds", elapsed)
  elseif elapsed < 3600 then
    return string.format("%dm", math.floor(elapsed / 60))
  else
    return string.format(
      "%dh%dm",
      math.floor(elapsed / 3600),
      math.floor((elapsed % 3600) / 60)
    )
  end
end

-- ---------------------------------------------------------------------------
-- Status dashboard rendering
-- ---------------------------------------------------------------------------

--- Render the dashboard buffer contents.
--- Accepts an optional pre-fetched running_set to avoid Docker calls
--- during rapid progress updates.
local function render_dashboard(running_set)
  local db = state.dashboard
  if not vim.api.nvim_buf_is_valid(db.buf) then
    return
  end

  local lines = {}
  local highlights = {}

  -- Single Docker call for all container statuses (unless provided).
  running_set = running_set or get_running_containers()

  table.insert(lines, "     Service                  Type    Status     Uptime")
  table.insert(lines, "     " .. string.rep("-", 56))

  for i, name in ipairs(service_order) do
    local service = state.services[name] or {}
    local spec = services[name] or {}
    local override = state.status_override[name]
    local active = is_service_active(name, running_set)
    local status_text = override or (active and "running" or "stopped")
    local uptime = active and format_uptime(service.started_at) or "-"
    local svc_type = spec.container and "docker" or "local"

    local line = string.format(
      "  %2d %-24s %-7s %-10s %s",
      i,
      name,
      svc_type,
      status_text,
      uptime
    )
    table.insert(lines, line)

    local line_idx = #lines - 1
    local status_col = 5 + 25 + 8
    local hl_group
    if override then
      hl_group = "DiagnosticWarn"
    elseif active then
      hl_group = "DiagnosticOk"
    else
      hl_group = "DiagnosticError"
    end
    table.insert(highlights, {
      line = line_idx,
      col_start = status_col,
      col_end = status_col + #status_text,
      group = hl_group,
    })
  end

  table.insert(lines, "")
  table.insert(lines, "  [enter/l] view  [r]estart  [S]tart  [s]tart all  [x] stop all  [q]uit")

  vim.bo[db.buf].modifiable = true
  vim.api.nvim_buf_set_lines(db.buf, 0, -1, false, lines)
  vim.bo[db.buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("floaterminal_dashboard")
  vim.api.nvim_buf_clear_namespace(db.buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      db.buf, ns, hl.group, hl.line, hl.col_start, hl.col_end
    )
  end
end

-- ---------------------------------------------------------------------------
-- Start / Stop all
-- ---------------------------------------------------------------------------

local function start_service_bg(name)
  local spec = services[name]
  if not spec then
    return false
  end

  if is_service_active(name) then
    return false
  end

  local service = get_service(name)
  ensure_fresh_buf(service)

  local opened = open_floating_win({
    buf = service.buf,
    title = " " .. name .. " ",
  })
  service.win = opened.win

  service.job_id = vim.fn.termopen(spec.cmd, {
    cwd = spec.cwd,
    on_exit = function()
      service.job_id = nil
      if not spec.container or not is_container_running(spec.container) then
        service.started_at = nil
      end
    end,
  })

  vim.bo[service.buf].buflisted = false
  vim.bo[service.buf].filetype = "floaterminal_service"

  local running = is_job_running(service.job_id)
  if running then
    service.started_at = os.time()
  end

  if vim.api.nvim_win_is_valid(service.win) then
    vim.api.nvim_win_hide(service.win)
  end

  -- Refocus the dashboard if it is open so it stays in front.
  local db = state.dashboard
  if vim.api.nvim_win_is_valid(db.win) then
    vim.api.nvim_set_current_win(db.win)
  end

  return running
end

local function start_all_services()
  local started = 0
  local skipped = 0
  local running_set = get_running_containers()
  local has_dashboard = vim.api.nvim_win_is_valid(state.dashboard.win)

  -- Mark services that will be started.
  for _, name in ipairs(service_order) do
    if not is_service_active(name, running_set) then
      state.status_override[name] = "starting..."
    end
  end

  if has_dashboard then
    render_dashboard(running_set)
    vim.cmd.redraw()
  end

  for _, name in ipairs(service_order) do
    if is_service_active(name, running_set) then
      skipped = skipped + 1
    else
      if start_service_bg(name) then
        started = started + 1
      end
      state.status_override[name] = nil
      if has_dashboard then
        render_dashboard(running_set)
        vim.cmd.redraw()
      end
    end
  end

  -- Clear any leftover overrides and do a full refresh.
  state.status_override = {}
  if has_dashboard then
    render_dashboard()
  end

  notify(string.format(
    "Started %d services (%d already running)", started, skipped
  ))
end

local function stop_all_services()
  local stopped = 0
  local has_dashboard = vim.api.nvim_win_is_valid(state.dashboard.win)

  -- 1. Kill all terminal jobs first (fast, non-blocking per service).
  for _, name in ipairs(service_order) do
    local service = state.services[name]
    if service and is_job_running(service.job_id) then
      kill_job(service.job_id)
      service.job_id = nil
      service.started_at = nil

      if vim.api.nvim_win_is_valid(service.win) then
        vim.api.nvim_win_hide(service.win)
      end
    end
  end

  -- 2. Check which Docker containers are actually running before stopping.
  local running_set = get_running_containers()

  -- Mark services that need stopping.
  for _, name in ipairs(service_order) do
    local spec = services[name]
    if spec and spec.stop_cmd then
      local needs_stop = not spec.container
        or running_set[spec.container]
      if needs_stop then
        state.status_override[name] = "stopping..."
      end
    end
  end

  if has_dashboard then
    render_dashboard(running_set)
    vim.cmd.redraw()
  end

  for _, name in ipairs(service_order) do
    local spec = services[name]
    if spec and spec.stop_cmd then
      local needs_stop = not spec.container
        or running_set[spec.container]
      if needs_stop then
        run_stop_cmd(spec.stop_cmd, spec.cwd)
        stopped = stopped + 1
        state.status_override[name] = nil
        if has_dashboard then
          render_dashboard(running_set)
          vim.cmd.redraw()
        end
      end
    end
  end

  -- Clear any leftover overrides and do a full refresh.
  state.status_override = {}
  if has_dashboard then
    render_dashboard()
  end

  notify(string.format("Stopped %d services", stopped))
end

local function dashboard_service_at_cursor()
  local db = state.dashboard
  if not vim.api.nvim_win_is_valid(db.win) then
    return nil
  end

  local row = vim.api.nvim_win_get_cursor(db.win)[1]
  local idx = row - 2
  if idx >= 1 and idx <= #service_order then
    return service_order[idx]
  end

  return nil
end

local function close_dashboard()
  local db = state.dashboard
  if db.timer then
    db.timer:stop()
    db.timer:close()
    db.timer = nil
  end

  if vim.api.nvim_win_is_valid(db.win) then
    vim.api.nvim_win_hide(db.win)
  end
end

open_dashboard = function()
  local db = state.dashboard

  if vim.api.nvim_win_is_valid(db.win) then
    close_dashboard()
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  db.buf = buf

  local opened = open_floating_win({
    buf = buf,
    width = 0.6,
    height = math.min(#service_order + 6, 20),
    title = " Service Status ",
  })
  db.win = opened.win

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.wo[opened.win].cursorline = true
  vim.wo[opened.win].number = false
  vim.wo[opened.win].relativenumber = false

  render_dashboard()

  vim.api.nvim_win_set_cursor(db.win, { 3, 0 })

  local map_opts = { buffer = buf, nowait = true, silent = true }

  vim.keymap.set("n", "q", close_dashboard, map_opts)
  vim.keymap.set("n", "<Esc>", close_dashboard, map_opts)

  vim.keymap.set("n", "<CR>", function()
    local name = dashboard_service_at_cursor()
    if name then
      close_dashboard()
      state.return_to_dashboard = true
      view_service_logs(name)
    end
  end, map_opts)

  vim.keymap.set("n", "l", function()
    local name = dashboard_service_at_cursor()
    if name then
      close_dashboard()
      state.return_to_dashboard = true
      view_service_logs(name)
    end
  end, map_opts)

  vim.keymap.set("n", "r", function()
    local name = dashboard_service_at_cursor()
    if name then
      state.status_override[name] = "stopping..."
      render_dashboard({})
      vim.cmd.redraw()
      full_stop_service(name)
      state.status_override[name] = "starting..."
      render_dashboard({})
      vim.cmd.redraw()
      start_service_bg(name)
      state.status_override[name] = nil
      render_dashboard()
      notify(string.format("Restarted %s", name))
    end
  end, map_opts)

  vim.keymap.set("n", "s", function()
    start_all_services()
  end, map_opts)

  vim.keymap.set("n", "S", function()
    local name = dashboard_service_at_cursor()
    if not name then
      return
    end
    if is_service_active(name) then
      notify(string.format("%s is already running", name))
      return
    end
    state.status_override[name] = "starting..."
    render_dashboard({})
    vim.cmd.redraw()
    start_service_bg(name)
    state.status_override[name] = nil
    render_dashboard()
    notify(string.format("Started %s", name))
  end, map_opts)

  vim.keymap.set("n", "x", function()
    stop_all_services()
  end, map_opts)

  local timer = vim.uv.new_timer()
  db.timer = timer
  timer:start(5000, 5000, vim.schedule_wrap(function()
    if not vim.api.nvim_win_is_valid(db.win) then
      timer:stop()
      timer:close()
      db.timer = nil
      return
    end

    render_dashboard()
  end))

  -- Stop the timer immediately when the buffer is wiped.
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      if db.timer then
        db.timer:stop()
        db.timer:close()
        db.timer = nil
      end
      db.buf = -1
      db.win = -1
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Telescope pickers
-- ---------------------------------------------------------------------------

local function telescope_pick(opts)
  opts = opts or {}
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    vim.ui.select(
      service_order,
      { prompt = opts.prompt or "Select service" },
      function(choice)
        if choice and opts.on_select then
          opts.on_select(choice)
        end
      end
    )
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local running_set = get_running_containers()
  local entries = {}
  for _, name in ipairs(service_order) do
    local active = is_service_active(name, running_set)
    local icon = active and " " or " "
    table.insert(entries, {
      display = string.format("%s %s", icon, name),
      name = name,
      running = active,
      ordinal = name,
    })
  end

  pickers.new({}, {
    prompt_title = opts.prompt or "Services",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and opts.on_select then
          opts.on_select(selection.value.name)
        end
      end)
      return true
    end,
  }):find()
end

local function telescope_multi_pick(opts)
  opts = opts or {}
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    if opts.fallback then
      opts.fallback()
    end
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local running_set = get_running_containers()
  local entries = {}
  for _, name in ipairs(service_order) do
    local active = is_service_active(name, running_set)
    local icon = active and " " or " "
    table.insert(entries, {
      display = string.format("%s %s", icon, name),
      name = name,
      running = active,
      ordinal = name,
    })
  end

  pickers.new({}, {
    prompt_title = opts.prompt
      or "Pick services (Tab to multi-select, Enter to confirm)",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if #selections == 0 then
          local entry = action_state.get_selected_entry()
          if entry then
            selections = { entry }
          end
        end
        actions.close(prompt_bufnr)
        if opts.on_select and #selections > 0 then
          local names = {}
          for _, sel in ipairs(selections) do
            table.insert(names, sel.value.name)
          end
          opts.on_select(names)
        end
      end)
      return true
    end,
  }):find()
end

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

vim.api.nvim_create_user_command("Floaterminal", toggle_terminal, {})
vim.keymap.set(
  { "n", "t" }, "<leader>tt",
  toggle_terminal,
  { desc = "Toggle generic floating terminal" }
)

vim.api.nvim_create_user_command("ServiceStart", function(opts)
  start_service(opts.args)
end, { nargs = 1, complete = function()
  return service_order
end })

vim.api.nvim_create_user_command("ServiceStop", function(opts)
  stop_service(opts.args)
end, { nargs = 1, complete = function()
  return service_order
end })

vim.api.nvim_create_user_command("ServiceRestart", function(opts)
  restart_service(opts.args)
end, { nargs = 1, complete = function()
  return service_order
end })

vim.api.nvim_create_user_command("ServiceToggle", function(opts)
  toggle_service(opts.args)
end, { nargs = 1, complete = function()
  return service_order
end })

vim.api.nvim_create_user_command("ServiceStartAll", start_all_services, {})
vim.api.nvim_create_user_command("ServiceStopAll", stop_all_services, {})

vim.api.nvim_create_user_command("ServiceStartPick", function()
  telescope_multi_pick({
    prompt = "Start services (Tab to multi-select, Enter to confirm)",
    on_select = function(names)
      local started = 0
      for _, name in ipairs(names) do
        if start_service_bg(name) then
          started = started + 1
        end
      end
      notify(string.format("Started %d services", started))
    end,
    fallback = start_all_services,
  })
end, {})

vim.api.nvim_create_user_command("ServiceStatus", open_dashboard, {})

vim.api.nvim_create_user_command("ServicePick", function()
  telescope_pick({
    prompt = "Toggle service",
    on_select = toggle_service,
  })
end, {})

vim.api.nvim_create_user_command("ServiceLogs", function()
  telescope_pick({
    prompt = "View service logs",
    on_select = view_service_logs,
  })
end, {})

-- ---------------------------------------------------------------------------
-- Auto-cleanup on exit
-- ---------------------------------------------------------------------------

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local running_set = get_running_containers()
    local has_active = false

    for _, name in ipairs(service_order) do
      local service = state.services[name]
      if service and is_job_running(service.job_id) then
        has_active = true
        break
      end
      local spec = services[name]
      if spec and spec.container and running_set[spec.container] then
        has_active = true
        break
      end
    end

    if not has_active then
      return
    end

    -- Kill terminal jobs first (fast).
    for _, name in ipairs(service_order) do
      local service = state.services[name]
      if service and is_job_running(service.job_id) then
        kill_job(service.job_id)
        service.job_id = nil
      end
    end

    -- Stop Docker containers.
    for _, name in ipairs(service_order) do
      local spec = services[name]
      if spec and spec.stop_cmd then
        local needs_stop = not spec.container
          or running_set[spec.container]
        if needs_stop then
          run_stop_cmd(spec.stop_cmd, spec.cwd)
        end
      end
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Keymaps
-- ---------------------------------------------------------------------------

vim.keymap.set("n", "<leader>ts", function()
  telescope_pick({
    prompt = "Toggle service",
    on_select = toggle_service,
  })
end, { desc = "Telescope: toggle service" })

vim.keymap.set("n", "<leader>tr", function()
  telescope_pick({
    prompt = "Restart service",
    on_select = restart_service,
  })
end, { desc = "Telescope: restart service" })

vim.keymap.set("n", "<leader>tx", function()
  telescope_pick({
    prompt = "Stop service",
    on_select = stop_service,
  })
end, { desc = "Telescope: stop service" })

vim.keymap.set("n", "<leader>tl", function()
  telescope_pick({
    prompt = "View service logs",
    on_select = view_service_logs,
  })
end, { desc = "Telescope: view service logs" })

vim.keymap.set("n", "<leader>ta", start_all_services, { desc = "Start all services" })
vim.keymap.set("n", "<leader>tX", stop_all_services, { desc = "Stop all services" })
vim.keymap.set("n", "<leader>td", open_dashboard, { desc = "Service status dashboard" })
vim.keymap.set("n", "<leader>tp", function()
  telescope_multi_pick({
    prompt = "Start services (Tab to multi-select, Enter to confirm)",
    on_select = function(names)
      local started = 0
      for _, name in ipairs(names) do
        if start_service_bg(name) then
          started = started + 1
        end
      end
      notify(string.format("Started %d services", started))
    end,
    fallback = start_all_services,
  })
end, { desc = "Pick and start services" })
