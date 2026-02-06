return {
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },

  services = {
    ridergateway = {
      cmd = "docker-compose up web-ridergateway",
      cwd = vim.fn.expand("~/workspace/ridergateway"),
      stop_cmd = "docker-compose stop web-ridergateway",
    },
    ridercore = {
      cmd = "docker-compose up web-ridercore",
      cwd = vim.fn.expand("~/workspace/ridercore"),
      stop_cmd = "docker-compose stop web-ridercore",
    },
    bitaksi_backend = {
      cmd = "npm start",
      cwd = vim.fn.expand("~/workspace/bitaksi-backend"),
    },
    rideraccount = {
      cmd = "docker-compose up web-rideraccount",
      cwd = vim.fn.expand("~/workspace/rideraccount"),
      stop_cmd = "docker-compose stop web-rideraccount",
    },
    operationservice = {
      cmd = "docker-compose up web-operation",
      cwd = vim.fn.expand("~/workspace/operationservice"),
      stop_cmd = "docker-compose stop web-operation",
    },
    pushnotification = {
      cmd = "docker-compose up consumer-pushnotification",
      cwd = vim.fn.expand("~/workspace/notification"),
      stop_cmd = "docker-compose stop consumer-pushnotification",
    },
    emailnotification = {
      cmd = "docker-compose up consumer-emailnotification",
      cwd = vim.fn.expand("~/workspace/notification"),
      stop_cmd = "docker-compose stop consumer-emailnotification",
    },
    smsnotification = {
      cmd = "docker-compose up consumer-smsnotification",
      cwd = vim.fn.expand("~/workspace/notification"),
      stop_cmd = "docker-compose stop consumer-smsnotification",
    },
  },
}
