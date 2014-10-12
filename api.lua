---
-- SQL specific API view
--
-- Copyright Tor Hveem <thveem> 2013-2014
--
--
local setmetatable = setmetatable
local ngx = ngx
local string = string
local cjson = require "cjson"
local io = require "io"
local pg = require "resty.postgres" -- https://github.com/azurewang/lua-resty-postgres
local assert = assert
local conf

module(...)

local mt = { __index = _M }

if not conf then
    local f = assert(io.open(ngx.var.document_root .. "/etc/config.json", "r"))
    local c = f:read("*all")
    f:close()

    conf = cjson.decode(c)
end

local function dbreq(sql)
    local db = pg:new()
    db:set_timeout(30000)
    local ok, err = db:connect(
        {
            host=conf.db.host,
            port=5432,
            database=conf.db.database,
            user=conf.db.user,
            password=conf.db.password,
            compact=false
        })
    if not ok then
        ngx.say(err)
    end
    ngx.log(ngx.ERR, '___ SQL ___'..sql)
    local res, err = db:query(sql)
    if not res then
        return cjson.encode(err)
    end
    db:set_keepalive(0,10)
    return cjson.encode(res)
end

-- Latest record in db
function current(match)
    local table = 'data_' .. match[1]
    return dbreq([[
    SELECT
        *,
        temp/100 AS rtemp,
        date_part('epoch', time) AS timestamp
    FROM ]]..table..[[
    ORDER BY time DESC LIMIT 1]])
end

function max(match)
    local key = ngx.req.get_uri_args()['key']
    if not key then ngx.exit(403) end
    -- Make sure valid request, only accept plain lowercase ascii string for key name
    local keytest = ngx.re.match(key, '[a-z]+', 'oj')
    if not keytest then ngx.exit(403) end

    local sql = [[
        SELECT
            date_trunc('day', time) AS time,
            MAX(]]..key..[[) AS ]]..key..[[
        FROM ]]..conf.db.table..[[
        WHERE date_part('year', time) < 2013
        GROUP BY 1
    ]]

    return dbreq(sql)
end

-- Last 60 samples from db
function recent(match)
    return dbreq([[SELECT
    *,
    SUM(rain) OVER (PARTITION by time ORDER by time DESC) AS dayrain
    FROM ]]..conf.db.table..[[
    ORDER BY time DESC
    LIMIT 60]])
end

-- Helper function to get a start argument and return SQL constrains
local function getDateConstrains(startarg, interval)
    local where = ''
    local andwhere = ''
    if startarg then
        local start
        local endpart = "1 year"
        if string.upper(startarg) == 'TODAY' then
            start = "CURRENT_DATE"
            endpart = "1 DAY"
        elseif string.lower(startarg) == 'yesterday' then
            start = "DATE 'yesterday'"
            endpart = '1 days'
        elseif string.upper(startarg) == '3DAY' then
            start = "CURRENT_TIMESTAMP - INTERVAL '3 days'"
            endpart = '3 days'
        elseif string.upper(startarg) == '2DAY' then
            start = "CURRENT_TIMESTAMP - INTERVAL '2 days'"
            endpart = '3 days'
        elseif string.upper(startarg) == 'WEEK' then
            start = "CURRENT_DATE - INTERVAL '1 week'"
            endpart = '1 week'
        elseif string.upper(startarg) == '7DAYS' then
            start = "CURRENT_DATE - INTERVAL '1 WEEK'"
            endpart = '1 WEEK'
        elseif string.upper(startarg) == 'MONTH' then
            -- old used this month, new version uses last 30 days
            --start = "to_date( to_char(current_date,'yyyy-MM') || '-01','yyyy-mm-dd')"
            start = "CURRENT_DATE - INTERVAL '1 MONTH'"
            endpart = "1 MONTH"
        elseif string.upper(startarg) == 'YEAR' then
            start = "date_trunc('year', current_timestamp)"
            endpart = "1 year"
        elseif string.upper(startarg) == 'ALL' then
            start = "DATE '1900-01-01'" -- Should be old enough :-)
            endpart = "200 years"
        else
            start = "DATE '" .. startarg .. "'"
        end
        -- use interval if provided, if not use the default endpart
        if not interval then
            interval = endpart
        end

        local wherepart = [[
        (
            time BETWEEN ]]..start..[[
            AND
            ]]..start..[[ + INTERVAL ']]..endpart..[['
        )
        ]]
        where = 'WHERE ' .. wherepart
        andwhere = 'AND ' .. wherepart
    end
    return where, andwhere
end

-- Function to return extremeties from database, min/maxes for different time intervals
function record(match)
    local table = 'data_' .. match[1]
    local key = match[2]
    local func = string.upper(match[3])
    local where, andwhere = getDateConstrains(ngx.req.get_uri_args()['start'])
    local sql

    -- some key needs convertion
    if key == 'temp' then
      key = 'temp/100'
    end

    if func == 'SUM' then
        -- The SUM part doesn't need the time of the record since the time is effectively over the whole scope
        sql = [[
            SELECT
            SUM(]]..key..[[) AS ]]..match[2]..[[
            FROM ]]..table..[[
            ]]..where..[[
        ]]
    else
        sql = [[
        SELECT
            time,
            date_trunc('second', age(NOW(), date_trunc('second', time))) AS age,
            ]]..key..[[ AS ]]..match[2]..[[
        FROM ]]..table..[[
        WHERE
        ]]..key..[[ =
        (
            SELECT
                ]]..func..[[(]]..key..[[)
            FROM ]]..table..[[
            ]]..where..[[
            LIMIT 1
        )
        ]]..andwhere..[[
        LIMIT 1
        ]]
    end

    return dbreq(sql)
end

--- Return weather data by hour, week, month, year, whatever..
function by_dateunit(match)
    local table = 'data_' .. match[1]
    local unit = 'hour'
    if match[2] then
        if match[2] == 'month' then
            unit = 'day'
        end
    elseif ngx.req.get_uri_args()['start'] == 'month' then
        unit = 'day'
    end
    -- get the date constraints
    local where, andwhere = getDateConstrains(ngx.req.get_uri_args()['start'])
    local sql = dbreq([[
    SELECT
        date_trunc(']]..unit..[[', time) AS time,
        AVG(temp/100) as rtemp,
        MIN(temp) as tempmin,
        MAX(temp) as tempmax,
        AVG(voc) as voc,
        MAX(voc) as vocmax,
        MIN(voc) as vocmin,
        AVG(pressure) as pressure,
        MIN(humidity) as humiditymin,
        AVG(humidity) as humidity,
        MAX(humidity) as humiditymax,
        MIN(light) as lightmin,
        AVG(light) as light,
        MAX(light) as lightmax,
        MIN(noise) as noisemin,
        AVG(noise) as noise,
        MAX(noise) as noisemax
    FROM ]]..table..[[
    ]]..where..[[
    GROUP BY 1
    ORDER BY time
    ]])
    return sql
end

function day(match)
    local where, andwhere = getDateConstrains(ngx.req.get_uri_args()['start'])
    local sql = dbreq([[
    SELECT
        *,
        SUM(rain) OVER (ORDER by time) AS dayrain
    FROM ]]..conf.db.table..[[
    ]]..where..[[
    ORDER BY time
    ]])
    return sql
end

function year(match)
    -- This function generates stats into a new table
    -- which is updated max once a day
    -- first it checks the latest record in the stats table
    -- and if latest date is older than today
    -- it will recreate the table
    local year = match[1]
    local syear = year .. '-01-01'
    local where = [[
        WHERE time BETWEEN DATE ']]..syear..[['
        AND DATE ']]..syear..[[' + INTERVAL '1 year'
    ]]

    local needsupdate = cjson.decode(dbreq[[
        SELECT
        MAX(time) < (NOW() - INTERVAL '24 hours') AS needsupdate
        FROM days
    ]])
    if needsupdate == ngx.null or needsupdate[1] == nil then
        needsupdate = true
    else
        if needsupdate[1]['needsupdate'] == 't' then
            needsupdate = true
        else
            needsupdate = false
        end
    end
    if needsupdate then
        -- Remove existing cache. This could be improved to only add missing data
        dbreq('DROP TABLE days')
        -- Create new cached table
        local gendays = dbreq([[
        CREATE TABLE days AS
            SELECT
                date_trunc('day', time) AS time,
                AVG(outtemp) as outtemp,
                MIN(outtemp) as tempmin,
                MAX(outtemp) as tempmax,
                AVG(dewpoint) as dewpoint,
                AVG(rain) as rain,
                MAX(b.dayrain) as dayrain,
                AVG(windspeed) as windspeed,
                MAX(windgust) as windgust,
                AVG(winddir) as winddir,
                AVG(barometer) as barometer,
                AVG(outhumidity) as outhumidity,
                AVG(intemp) as intemp,
                AVG(inhumidity) as inhumidity,
                AVG(heatindex) as heatindex,
                AVG(windchill) as windchill
            FROM ]]..conf.db.table..[[ AS a
            LEFT OUTER JOIN
            (
                SELECT
                    DISTINCT date_trunc('day', time) AS hour,
                    SUM(rain) OVER (PARTITION BY date_trunc('day', time) ORDER by time) AS dayrain
                    FROM ]]..conf.db.table..[[ ORDER BY 1
            ) AS b
            ON a.time = b.hour
            GROUP BY 1
            ORDER BY time
            ]])
    end
    local sql = [[
        SELECT *
        FROM days
        ]]..where
    return dbreq(sql)
end

function windhist(match)
    local where, andwhere = getDateConstrains(ngx.req.get_uri_args()['start'])
    return dbreq([[
        SELECT count(*), ((winddir/10)::int*10)+0 as d, avg(windspeed)*0.539956803  as avg
        FROM ]]..conf.db.table..[[
        ]]..where..[[
        GROUP BY 2
        ORDER BY 2
    ]])
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        ngx.log(ngx.ERR, 'attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
