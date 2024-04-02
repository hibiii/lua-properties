local PropertiesReader = require 'PropertiesReader'

local props = PropertiesReader.read(io.lines 'test.properties')

-- Sorting keys
local keys = {}
do
    local key = next(props)
    while key ~= nil do
        keys[#keys+1] = key
        key = next(props, key)
    end
    table.sort(keys)
end

-- Printing
for i = 1, #keys do
    print('[\''.. keys[i] ..'\'] = \'' .. props[keys[i]] .. '\'')
end
