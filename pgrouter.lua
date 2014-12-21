-- 
-- A simple API adapter 
--
-- Copyright Tor Hveem <thveem> 2013-2014
--

local cjson = require "cjson"

-- Load our API commands
local api = require "api"

-- mapping patterns to query views
local routes = {
    ['(\\w+)/current']      = api.current,
    ['(\\w+)/record/([a-z_]+)/([a-z]+)']= api.record,
    ['(\\w+)/hour']       = api.by_dateunit,
    ['max']               = api.max,
    ['year/([0-9]{4})']   = api.year,
    ['day']               = api.day,
    ['recent']            = api.recent,
    ['station']           = api.meta,
    ['windhist']          = api.windhist,
    ['(month)']           = api.by_dateunit,
}
-- Set the content type
ngx.header.content_type = 'application/json';
-- Our URL base, must match location in nginx config
local BASE = '/api/'
-- iterate route patterns and find view
for pattern, view in pairs(routes) do
    local uri = '^' .. BASE .. pattern
    local match = ngx.re.match(ngx.var.uri, uri, "oj") -- regex mather in compile mode
    if match then
        local ret, exit = view(match) 
        local callback = ngx.req.get_uri_args()['callback']
        if callback then
            ret = callback .. '(' .. ret .. ');'
        end
        -- Allow CORS
        ngx.header['Access-Control-Allow-Origin'] = '*';
        -- Print the returned res
        ngx.print(ret)
        -- If not given exit, then assume OK
        if not exit then exit = ngx.HTTP_OK end
        -- Exit with returned exit value
        ngx.exit( exit )
    end
end
-- no match, return 404
ngx.exit( ngx.HTTP_NOT_FOUND )
