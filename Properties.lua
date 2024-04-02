---@version 5.2
local metatable = {}
metatable.__newindex = function(prop, key, value)
    if type(key) ~= 'string' then
        error 'Properties does not support non-string keys'
    end
    if value == nil then
        rawset(prop, key, nil)
        return
    end
    if type(value) ~= 'string' and type(value) ~= 'number' then
        error ('Properties does not support non-string value \''..value..'\'')
    end
    if type(value) == 'number' then
        value = tostring(value)
    end
    rawset(prop, key, value)
end

local Properties = {}
---Returns an empty `Properties` table. This is different from an empty Lua
---table because it  verifies that keys and values are strings before they are
---put, and will error out if they aren't.
---@return table properties
Properties.new = function()
    return setmetatable({}, metatable)
end

return Properties
