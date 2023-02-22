local kong_meta = require "kong.meta"
local proxy_wasm = require "resty.http.proxy_wasm"


local ProxyWasmHandler = {
  VERSION = kong_meta.version,
  PRIORITY = 1500, -- TODO: choose
}


local cache = setmetatable({}, { __mode = "k" })


local function get_c_ops(conf)
  if cache[conf] then
    return cache[conf]
  end

  local c_ops, err = proxy_wasm.new(conf.filters)
  if not c_ops then
    error(err)
  end

  local ok, err = proxy_wasm.load(c_ops)
  if not ok then
    error(err)
  end

  cache[conf] = c_ops
  return c_ops
end


function ProxyWasmHandler:access(conf)
  local c_ops, err = get_c_ops(conf)
  if not c_ops then
    error(err)
  end

  local ok, err = proxy_wasm.attach(c_ops)
  if not ok then
    error(err)
  end

  local route = kong.router.get_route()
  if route then
    local ok, err = proxy_wasm.set_property("kong.route_id", route.id)
    print("SET R PROP ", ok, " ", err, " ", route.id)
  end
  local service = kong.router.get_service()
  if service then
    local ok, err = proxy_wasm.set_property("kong.service_id", service.id)
    print("SET S PROP ", ok, " ", err, " ", service.id)
  end

  proxy_wasm.resume("access")
end


return ProxyWasmHandler
