

toString=function(o)
    local res = ""
    if type(o)=="number" then
        res = res.. o
    elseif type(o)=="string" then
        res = res .. '"' .. o ..'"'
    elseif type(o)=="table" then
        res = res .. "{"
        for k,v in pairs(o) do
            res =  res .. toString(k) .. "=" .. toString(v) .. ", "
        end
        res = res .. "}"
    elseif type(o) == "boolean" then
        if o then
            res = "true"
        else
            res = "false"
        end
    else
        res = res .. "--" .. type(o) .. "--"
    end
    return res
end

function getAllData(t, prevData)
    -- if prevData == nil, start empty, otherwise start with prevData
    local data = prevData or {}
  
    -- copy all the attributes from t
    for k,v in pairs(t) do
      data[k] = data[k] or v
    end
  
    -- get t's metatable, or exit if not existing
    local mt = getmetatable(t)
    if type(mt)~='table' then return data end
  
    -- get the __index from mt, or exit if not table
    local index = mt.__index
    if type(index)~='table' then return data end
  
    -- include the data from index into data, recursively, and return
    return getAllData(index, data)
  end
