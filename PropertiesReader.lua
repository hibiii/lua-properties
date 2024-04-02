---@version 5.2
local Properties = require 'Properties'
local PropertiesReader = {}

---Reads a physical line from a file, with left whitespace and comments trimmed
---out.
---
---Takes an iterator returning string, and returns:
--- - nil on iterator end
--- - string on empty line
--- - the line with left whitespace trimmed, if it has meaningful content.
---@param reader fun():string|nil
---@return string|nil line
local readPhysicalLine = function(reader)
    local line = reader()
    if not line then
        return nil
    end
    return line:match '^[ \t\f]*(.*)'
end


---Continuously tries reading physical lines until there's meaningful content.
---This function will always return either nil or a string with content.
---@param reader fun():string|nil
---@return string|nil line
local readPhysLinesUntilContent = function(reader)
    local physLine = nil
    repeat
        physLine = readPhysicalLine(reader)
        if physLine ~= nil and physLine:match('^[ \t\f]*[#!]') then
            physLine = ''
        end
    until physLine ~= ''
    return physLine
end


-- Constants related to escaping
local BACKSLASH = string.byte '\\'
local ESCAPES = {
    [string.byte 't'] = '\t',
    [string.byte 'r'] = '\r',
    [string.byte 'n'] = '\n',
    [string.byte 'f'] = '\f',
}
local UNICODE_ESCAPE = string.byte 'u'

---Processes escape sequences vaguely according to the way the Java impl
---of Properties proccesses them.
---
---**Notice about implementation details**: Unicode libraries are not available
---on Lua 5.2, which this code targets. Therefore, the `\uxxxx` escape sequence
---is *not* implemented, and will be pasted in verbatim, including backslash.
---
---The following escapes are treated here:
--- - `\t` into tab stop
--- - `\r` into carriage return
--- - `\n` into line feed
--- - `\f` into form feed
--- - arbitrary character escaping
---@param str string
---@returns string
local renderEscapes = function(str)
    local s = ''
    local i = 1
    while i <= #str do
        local escape
        if str:byte(i) ~= BACKSLASH then
            s = s .. str:sub(i, i)
            goto continue
        end
        i = i + 1
        if i > #str then
            break
        end
        escape = str:byte(i)
        if escape == UNICODE_ESCAPE then
            -- NOTE: Unicode escapes are NOT supported --
            s = s .. str:sub(i - 1, i)
            goto continue
        end
        s = s .. (ESCAPES[escape] or str:sub(i, i))
        ::continue::
        i = i + 1
    end
    return s
end


---Finds the indices of the end of the key and the start of the value. The
---returned indices take into account the existence of the separator.
---@param line string
---@return number keyEnd, number valueStart
local findSeparator = function(line)
    -- FIXME: Make logic simpler and more readable
    local keyEndGraph, valueStartGraph = line:find '[^\\][=:]'
    local keyEndSpace, valueStartSpace = line:find '[^\\][ \t\f]'
    if keyEndGraph and keyEndSpace then
        if keyEndGraph < keyEndSpace then
            return keyEndGraph, valueStartGraph + 1
        else
            if line:sub(keyEndSpace, valueStartGraph):match '[^\\][ \t\f]+[=:]' then
                return keyEndSpace, valueStartGraph + 1
            end
        end
    end
    if not keyEndSpace then
        if not keyEndGraph then
            return #line, #line + 1
        else
            return keyEndGraph, valueStartGraph + 1
        end
    else
        if keyEndGraph and keyEndGraph == keyEndSpace + 1 then
            return keyEndGraph, valueStartGraph + 1
        else
            return keyEndSpace, valueStartSpace + 1
        end
    end
end


---Reads one or more physical lines from an iterator-style reader function and
---returns a key-value pair, according to the way Properties files are parsed
---in Java.
---
---This function returns:
--- - nil if it's reached the end of the file
--- - two strings representing a key-value pair.
---@param reader fun():string|nil
---@return string|nil key
---@return string|nil value
local readVirtualLine = function(reader)
    local line = readPhysLinesUntilContent(reader)
    if line == nil then
        return nil
    end
    local rest = '' ---@type string|nil
    while line:match '[^\\]\\$' and rest ~= nil do
        line = line:sub(1, #line - 1)
        rest = readPhysicalLine(reader)
        if rest ~= nil then
            line = line .. rest
        end
    end
    local keyEnd, valueStart = findSeparator(line)
    local key = line:sub(1, keyEnd) or ''
    local value = line:sub(valueStart, #line) or ''
    value = value:match '^[ \t\f]*(.*)'
    key = renderEscapes(key)
    value = renderEscapes(value)
    return key, value
end

---Creates a new Properties given an iterator that behaves like `file:read '*l'`
---or `file:lines '*l'`.
---
---This function can be invoked, for example, like
---`PropertiesReader.new(propFile:lines())`.
---@param reader fun():string|nil
PropertiesReader.read = function(reader)
    local props = Properties.new()
    for key, value in function() return readVirtualLine(reader) end do
        props[key] = value
    end
    return props
end

return PropertiesReader
