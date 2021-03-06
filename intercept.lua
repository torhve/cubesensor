local cjson = require('cjson')
local pg = require("resty.postgres")
local ngx = require'ngx'
local conf = false

-- Debugging
local p = function(s)
  if type(s) == 'string' then
    ngx.log(ngx.ERR, s)
  else
    ngx.log(ngx.ERR, cjson.encode(s))
  end
end

-- Read conf for database from disk
if not conf then
  local f = assert(io.open(ngx.var.document_root .. "/etc/config.json", "r"))
  local c = f:read("*all")
  f:close()
  conf = cjson.decode(c)
end

-- Database request
local dbreq = function(sql)
  local db = pg:new()
  db:set_timeout(30000)
  local ok, err = db:connect({
    host = conf.db.host,
    port = 5432,
    database = conf.db.database,
    user = conf.db.user,
    password = conf.db.password,
    compact = false
  })
  if not ok then
    p(err)
  end
  local res res, err = db:query(sql)
  if not res then
    return cjson.encode(err)
  end
  db:set_keepalive(0, 10)
  return cjson.encode(res)
end

-- Read the full body from the request
ngx.req.read_body()
-- get the JSON
local body = ngx.req.get_body_data()
local success, jdata = pcall(function()
  return cjson.decode(body)
end)
if success then
  local ok, err = pcall(function()
    local data = jdata.data
    if data then
      local time = jdata.time
      for _, cube in pairs(data) do
        local id = cube.cube
        -- Delete a few keys we don't want to store in the SQL
        cube.cube = nil
        cube.firmware = nil
        cube.charging = nil

        local keys = {}
        local values = {}

        for key, val in pairs(cube) do
            -- Algos from http://www.visionect.com/blog/raspberry-pi-e-paper/
            table.insert(keys, key)
            if key == 'voc' then
                val = math.max(val - 900, 0)*0.4 + math.min(val, 900)
            elseif key == 'light' then
                val = 10/6.0*(1+(val/1024.0)*4.787*math.exp(-(math.pow((val-2048)/400.0+1, 2)/50.0))) * (102400.0/math.max(15, val) - 25)
            elseif key == 'humidity' then
                val = val/100
            end
            -- Convert boolean to string values
            if type(val) == 'boolean' then
                val = "'"..tostring(val).."'"
            end
            table.insert(values, val)
        end
        keys[#keys + 1] = 'time'
        values[#values + 1] = "date_trunc('minute', to_timestamp(" .. tostring(time) .. "))"
        local sql = [[
            INSERT INTO
            data_]] .. id .. [[
            (]] .. table.concat(keys, ',') .. [[)
            VALUES (]] .. table.concat(values, ',') .. [[)
        ]]
        local res = dbreq(sql)
        if res ~= '{}' then
            p(sql)
            p(res)
        end

        -- Insert data into influxdb
        local influxdata = {}
        local m2pt = function(id2, field, value)
            if value == 'false' then
                value = 0
            elseif value == 'true' then
                value = 1
            end
            if field == 'temp' then
                value = value/100
            end
            return string.format("%s,id=%s value=%f", field, id2, value)
        end
        -- Skip last key which is time
        for i=1,#keys-1 do
            table.insert(influxdata, m2pt(id, keys[i], values[i]))
        end
        local database = 'cubes'
        influxdata = table.concat(influxdata, '\n')
        local _ = ngx.location.capture('/write?db='..database,
            { method = ngx.HTTP_POST, body = influxdata }
        )
      end
    end
  end)
  if not (ok) then
    p("Error with inserting data: " .. tostring(err))
  end
end
