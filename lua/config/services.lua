local overrides = vim.fn.expand("~/.local/state/devup/overrides")

local function docker_cmd(compose_dir, override_file, service_name, action)
  action = action or "up --no-build"
  return string.format(
    "docker compose -f docker-compose.yml -f %s/%s %s %s",
    overrides,
    override_file,
    action,
    service_name
  )
end

local function nvm_cmd(node_version, run_cmd)
  return string.format(
    "bash -c 'source ~/.nvm/nvm.sh && nvm use %s && %s'",
    node_version,
    run_cmd
  )
end

return {
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },

  services = {
    ridergateway = {
      cmd = docker_cmd(".", "ridergateway.yml", "web-ridergateway"),
      cwd = vim.fn.expand("~/workspace/ridergateway"),
      stop_cmd = docker_cmd(".", "ridergateway.yml", "web-ridergateway", "stop"),
      container = "web-ridergateway",
    },
    ridercore = {
      cmd = docker_cmd(".", "ridercore.yml", "web-ridercore"),
      cwd = vim.fn.expand("~/workspace/ridercore"),
      stop_cmd = docker_cmd(".", "ridercore.yml", "web-ridercore", "stop"),
      container = "web-ridercore",
    },
    rideraccount = {
      cmd = docker_cmd(".", "rideraccount.yml", "web-rideraccount"),
      cwd = vim.fn.expand("~/workspace/rideraccount"),
      stop_cmd = docker_cmd(".", "rideraccount.yml", "web-rideraccount", "stop"),
      container = "web-rideraccount",
    },
    rideraccountlistener = {
      cmd = docker_cmd(".", "rideraccount.yml", "listener-rideraccount"),
      cwd = vim.fn.expand("~/workspace/rideraccount"),
      stop_cmd = docker_cmd(".", "rideraccount.yml", "listener-rideraccount", "stop"),
      container = "consumer-rideraccountlistener",
    },
    bitaksi_backend = {
      cmd = nvm_cmd("8.17", "npm start"),
      cwd = vim.fn.expand("~/workspace/bitaksi-backend"),
    },
    tripservice = {
      cmd = nvm_cmd("18.20", "npm run dev"),
      cwd = vim.fn.expand("~/workspace/tripservice"),
    },
    tripapi = {
      cmd = docker_cmd(".", "trip.yml", "web-trip"),
      cwd = vim.fn.expand("~/workspace/trip"),
      stop_cmd = docker_cmd(".", "trip.yml", "web-trip", "stop"),
      container = "web-trip",
    },
    triplive = {
      cmd = docker_cmd(".", "trip.yml", "live-trip"),
      cwd = vim.fn.expand("~/workspace/trip"),
      stop_cmd = docker_cmd(".", "trip.yml", "live-trip", "stop"),
      container = "live-trip",
    },
    pushnotification = {
      cmd = docker_cmd(".", "notification.yml", "consumer-pushnotification"),
      cwd = vim.fn.expand("~/workspace/notification"),
      stop_cmd = docker_cmd(".", "notification.yml", "consumer-pushnotification", "stop"),
      container = "consumer-pushnotification",
    },
    operation = {
      cmd = docker_cmd(".", "operationservice.yml", "web-operation"),
      cwd = vim.fn.expand("~/workspace/operationservice"),
      stop_cmd = docker_cmd(".", "operationservice.yml", "web-operation", "stop"),
      container = "web-operation",
    },
    cafemcore = {
      cmd = "make run",
      cwd = vim.fn.expand("~/workspace/go/cafem-studio/cafemcore"),
    },
  },
}
