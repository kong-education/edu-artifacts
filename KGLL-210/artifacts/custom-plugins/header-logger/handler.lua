local kong = kong
local HeaderLogger = {
  PRIORITY = 1000,
  VERSION = "1.0",
}

-- Log helper using configured path
local function log_to_file(file_path, data)
  local file, err = io.open(file_path, "a")
  if not file then
    kong.log.err("Failed to open log file: ", err)
    return
  end
  file:write(data .. "\n")
  file:close()
end

function HeaderLogger:access(conf)
  local headers = kong.request.get_headers()
  local log_data = "[Request Headers]\n"
  for k, v in pairs(headers) do
    log_data = log_data .. k .. ": " .. v .. "\n"
  end
  log_data = log_data .. "---------------------------"
  log_to_file(conf.file_path, log_data)
end

function HeaderLogger:header_filter(conf)
  local headers = kong.response.get_headers()
  local log_data = "[Response Headers]\n"
  for k, v in pairs(headers) do
    log_data = log_data .. k .. ": " .. v .. "\n"
  end
  log_data = log_data .. "==========================="
  log_to_file(conf.file_path, log_data)
end

return HeaderLogger
