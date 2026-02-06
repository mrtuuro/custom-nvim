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
}

local float_opts = vim.tbl_deep_extend("force", {
  width = 0.8,
  height = 0.8,
  border = "rounded",
}, service_config.float or {})

local services = service_config.services or {}

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

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = opts.border or float_opts.border,
  })

  return { buf = buf, win = win }
end

local function is_job_running(job_id)
  if not job_id or job_id <= 0 then
    return false
  end

  return vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Floaterminal" })
end

local function run_detached_cmd(cmd, cwd)
  if not cmd then
    return
  end

  vim.fn.jobstart(cmd, {
    cwd = cwd,
    detach = false,
  })
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
  }
  state.services[name] = entry

  return entry
end

local function open_service(name)
  if not services[name] then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return nil
  end

  local service = get_service(name)
  if vim.api.nvim_win_is_valid(service.win) then
    vim.api.nvim_set_current_win(service.win)
    return service
  end

  local opened = open_floating_win({ buf = service.buf })
  service.buf = opened.buf
  service.win = opened.win

  return service
end

local function start_service(name)
  local spec = services[name]
  if not spec then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return
  end

  local service = open_service(name)
  if not service then
    return
  end

  if is_job_running(service.job_id) then
    notify(string.format("%s is already running", name))
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
    end,
  })

  vim.bo[service.buf].buflisted = false
  vim.bo[service.buf].filetype = "floaterminal_service"

  if not is_job_running(service.job_id) then
    notify(string.format("Failed to start %s", name), vim.log.levels.ERROR)
    return
  end

  notify(string.format("Started %s", name))
end

local function stop_service(name)
  local spec = services[name]
  if not spec then
    notify(string.format("Unknown service '%s'", name), vim.log.levels.ERROR)
    return
  end

  local service = state.services[name]
  if service and is_job_running(service.job_id) then
    -- Send Ctrl-C first so foreground tools like docker compose can shut down cleanly.
    vim.fn.chansend(service.job_id, "\003")
    local wait_result = vim.fn.jobwait({ service.job_id }, 1500)[1]
    if wait_result == -1 then
      vim.fn.jobstop(service.job_id)
    end

    service.job_id = nil

    if vim.api.nvim_win_is_valid(service.win) then
      vim.api.nvim_win_hide(service.win)
    end
  end

  if spec.stop_cmd then
    run_detached_cmd(spec.stop_cmd, spec.cwd)
  end

  notify(string.format("Stopped %s", name))
end

local function restart_service(name)
  if state.services[name] and is_job_running(state.services[name].job_id) then
    stop_service(name)
  end

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

  service = open_service(name)
  if not service then
    return
  end

  if not is_job_running(service.job_id) then
    start_service(name)
  end
end

local function with_service_select(cb, prompt)
  local names = vim.tbl_keys(services)
  table.sort(names)

  if #names == 0 then
    notify("No services configured. Add services to lua/config/services.lua", vim.log.levels.WARN)
    return
  end

  vim.ui.select(names, { prompt = prompt or "Select service" }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

vim.api.nvim_create_user_command("Floaterminal", toggle_terminal, {})
vim.keymap.set({ "n", "t" }, "<leader>tt", toggle_terminal, { desc = "Toggle generic floating terminal" })

vim.api.nvim_create_user_command("ServiceStart", function(opts)
  start_service(opts.args)
end, { nargs = 1, complete = function()
  return vim.tbl_keys(services)
end })

vim.api.nvim_create_user_command("ServiceStop", function(opts)
  stop_service(opts.args)
end, { nargs = 1, complete = function()
  return vim.tbl_keys(services)
end })

vim.api.nvim_create_user_command("ServiceRestart", function(opts)
  restart_service(opts.args)
end, { nargs = 1, complete = function()
  return vim.tbl_keys(services)
end })

vim.api.nvim_create_user_command("ServiceToggle", function(opts)
  toggle_service(opts.args)
end, { nargs = 1, complete = function()
  return vim.tbl_keys(services)
end })

vim.api.nvim_create_user_command("ServicePick", function()
  with_service_select(toggle_service, "Toggle service")
end, {})

vim.keymap.set("n", "<leader>ts", function()
  with_service_select(toggle_service, "Toggle service")
end, { desc = "Toggle service terminal" })

vim.keymap.set("n", "<leader>tr", function()
  with_service_select(restart_service, "Restart service")
end, { desc = "Restart service" })

vim.keymap.set("n", "<leader>tx", function()
  with_service_select(stop_service, "Stop service")
end, { desc = "Stop service" })
