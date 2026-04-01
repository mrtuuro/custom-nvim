local ok, config = pcall(require, "config.git_workflow")
if not ok then
  config = {}
end

local settings = vim.tbl_deep_extend("force", {
  remote = "origin",
  base_branch = "master",
  restore_branch_after_propagate = true,
  dependencies = {},
}, config)

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git Workflow" })
end

local function split_lines(text)
  if not text or text == "" then
    return {}
  end

  local lines = vim.split(text, "\n", { plain = true, trimempty = true })
  return lines
end

local function run_git(args, cwd)
  local cmd = vim.list_extend({ "git" }, args)

  if vim.system then
    local res = vim.system(cmd, {
      cwd = cwd,
      text = true,
    }):wait()

    local out = split_lines(res.stdout)
    local err = split_lines(res.stderr)

    return {
      code = res.code,
      stdout = out,
      stderr = err,
    }
  end

  local escaped = {}
  for _, part in ipairs(cmd) do
    table.insert(escaped, vim.fn.shellescape(part))
  end

  local full = table.concat(escaped, " ")
  if cwd and cwd ~= "" then
    full = string.format("cd %s && %s", vim.fn.shellescape(cwd), full)
  end

  local out = vim.fn.systemlist(full)
  local code = vim.v.shell_error

  return {
    code = code,
    stdout = out,
    stderr = {},
  }
end

local function git_root()
  local res = run_git({ "rev-parse", "--show-toplevel" })
  if res.code ~= 0 or not res.stdout[1] then
    return nil
  end

  return res.stdout[1]
end

local function current_branch(root)
  local res = run_git({ "rev-parse", "--abbrev-ref", "HEAD" }, root)
  if res.code ~= 0 or not res.stdout[1] then
    return nil
  end

  return res.stdout[1]
end

local function branch_exists(branch, root)
  local res = run_git({ "rev-parse", "--verify", branch }, root)
  return res.code == 0
end

local function is_clean(root)
  local res = run_git({ "status", "--porcelain" }, root)
  if res.code ~= 0 then
    return false
  end

  return #res.stdout == 0
end

local function fetch_base(root, remote, base)
  local res = run_git({ "fetch", remote, base }, root)
  if res.code ~= 0 then
    local msg = (#res.stderr > 0 and table.concat(res.stderr, "\n")) or "Failed to fetch base branch"
    notify(msg, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function merge_branch(root, branch)
  local res = run_git({ "merge", "--no-edit", branch }, root)
  if res.code ~= 0 then
    local msg = (#res.stdout > 0 and table.concat(res.stdout, "\n"))
      or (#res.stderr > 0 and table.concat(res.stderr, "\n"))
      or "Merge failed"
    notify(msg, vim.log.levels.ERROR)
    return false
  end

  return true
end

local function sync_current_from_base(opts)
  opts = opts or {}
  local root = git_root()
  if not root then
    notify("Not inside a git repository", vim.log.levels.ERROR)
    return
  end

  if not is_clean(root) then
    notify("Working tree is not clean. Commit/stash first.", vim.log.levels.WARN)
    return
  end

  local base = opts.base or settings.base_branch
  local remote = settings.remote
  local remote_ref = string.format("%s/%s", remote, base)

  if not fetch_base(root, remote, base) then
    return
  end

  local missing = run_git({ "rev-list", "--count", "HEAD.." .. remote_ref }, root)
  if missing.code ~= 0 then
    notify("Failed to compare with base branch", vim.log.levels.ERROR)
    return
  end

  local pending = tonumber(missing.stdout[1] or "0") or 0
  if pending == 0 then
    notify(string.format("Current branch already includes %s", remote_ref))
    return
  end

  if merge_branch(root, remote_ref) then
    notify(string.format("Merged %s into current branch", remote_ref))
  end
end

local function propagate_branch(source, target)
  local root = git_root()
  if not root then
    notify("Not inside a git repository", vim.log.levels.ERROR)
    return
  end

  if not source or source == "" or not target or target == "" then
    notify("Usage: :BranchPropagate <source_branch> <target_branch>", vim.log.levels.WARN)
    return
  end

  if not is_clean(root) then
    notify("Working tree is not clean. Commit/stash first.", vim.log.levels.WARN)
    return
  end

  if not branch_exists(source, root) then
    notify(string.format("Source branch '%s' does not exist", source), vim.log.levels.ERROR)
    return
  end

  if not branch_exists(target, root) then
    notify(string.format("Target branch '%s' does not exist", target), vim.log.levels.ERROR)
    return
  end

  local original = current_branch(root)
  if not original then
    notify("Failed to detect current branch", vim.log.levels.ERROR)
    return
  end

  if original ~= target then
    local checked = run_git({ "checkout", target }, root)
    if checked.code ~= 0 then
      local msg = (#checked.stderr > 0 and table.concat(checked.stderr, "\n")) or "Failed to checkout target branch"
      notify(msg, vim.log.levels.ERROR)
      return
    end
  end

  local ok_merge = merge_branch(root, source)
  if not ok_merge then
    notify("Resolve conflicts on target branch before continuing.", vim.log.levels.WARN)
    return
  end

  if settings.restore_branch_after_propagate and original ~= target then
    local back = run_git({ "checkout", original }, root)
    if back.code ~= 0 then
      local msg = (#back.stderr > 0 and table.concat(back.stderr, "\n")) or "Merged, but failed to restore original branch"
      notify(msg, vim.log.levels.WARN)
      return
    end
  end

  notify(string.format("Merged '%s' into '%s'", source, target))
end

local function sync_dependency(target)
  local root = git_root()
  if not root then
    notify("Not inside a git repository", vim.log.levels.ERROR)
    return
  end

  local branch = target
  if not branch or branch == "" then
    branch = current_branch(root)
  end

  if not branch or branch == "" then
    notify("Could not determine target branch", vim.log.levels.ERROR)
    return
  end

  local source = settings.dependencies[branch]
  if not source then
    notify(string.format("No dependency configured for '%s'", branch), vim.log.levels.WARN)
    return
  end

  propagate_branch(source, branch)
end

vim.api.nvim_create_user_command("BranchSyncBase", function(opts)
  sync_current_from_base({ base = opts.args ~= "" and opts.args or nil })
end, {
  nargs = "?",
  complete = function()
    return { settings.base_branch }
  end,
})

vim.api.nvim_create_user_command("BranchPropagate", function(opts)
  local parts = vim.split(vim.trim(opts.args), "%s+", { plain = false })
  propagate_branch(parts[1], parts[2])
end, { nargs = "+" })

vim.api.nvim_create_user_command("BranchSyncDependency", function(opts)
  local arg = opts.args ~= "" and opts.args or nil
  sync_dependency(arg)
end, {
  nargs = "?",
  complete = function()
    return vim.tbl_keys(settings.dependencies)
  end,
})

vim.keymap.set("n", "<leader>gb", function()
  sync_current_from_base()
end, { desc = "Sync current branch from origin/master" })

vim.keymap.set("n", "<leader>gd", function()
  sync_dependency(nil)
end, { desc = "Sync current branch from configured dependency" })
