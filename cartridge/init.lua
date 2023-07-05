---@class cartridge LÖVE save data module
---@field private _data table The data we hold
---@field private _filepath string The filepath to the save data
---@field private _config { writeOnFlush: true } Configuration

local cartridge =
{
    _VERSION     = "0.1.0",
    _DESCRIPTION = "LÖVE save data module",
    _LICENSE     = [[
       MIT LICENSE
       Copyright (c) TurtleP
       Permission is hereby granted, free of charge, to any person obtaining a
       copy of this software and associated documentation files (the
       "Software"), to deal in the Software without restriction, including
       without limitation the rights to use, copy, modify, merge, publish,
       distribute, sublicense, and/or sell copies of the Software, and to
       permit persons to whom the Software is furnished to do so, subject to
       the following conditions:
       The above copyright notice and this permission notice shall be included
       in all copies or substantial portions of the Software.
       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
       OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
       MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
       IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
       CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
       TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
       SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   ]],

    _data        = nil,
    _filepath    = nil,
    _config      = { writeOnFlush = true }
}

local path = (...):gsub("%.init", "")
local msgpack = require(path .. ".msgpack")

local function export_save()
    love.filesystem.write(cartridge._filepath, msgpack.pack(cartridge._data))
end

local function setup_config(config)
    cartridge._config.writeOnFlush = (config and config.writeOnFlush) or true
end

---Loads or initializes save data
---@param filepath string The path to the save file
---@param config? table The configuration to use for the module
---@return self
function cartridge.open(filepath, config)
    assert(filepath and type(filepath) == "string", ("bad argument #1: expected string, got %s"):format(filepath))
    setup_config(config)

    cartridge._filepath = filepath

    if not love.filesystem.getInfo(filepath, "file") then
        cartridge._data = {}
        return cartridge
    end

    local contents, size_or_error = love.filesystem.read(filepath)
    assert(contents ~= nil, size_or_error)

    cartridge._data = msgpack.unpack(contents)

    return cartridge
end

---Read a key from the save data table
---@param key string The value from the save data table
---@return table data The data that was read inside of a table
function cartridge.read(key)
    assert(cartridge._data, "cartridge was not loaded with data.")
    assert(cartridge._data[key], ("key '%s' does not exist in the save data."):format(key))

    local value = cartridge._data[key]

    if type(value) == "table" then
        return value
    end

    return { [key] = value }
end

---Writes a table of data to the save data
---@param key string The key to write to in the save data
---@param data table|any The data table to write for the key in the save data
function cartridge.write(key, data)
    assert(key, ("bad argument #1 for 'key': expected string, got %s"):format(type(key)))

    if type(data) == "string" then
        return cartridge.write_value(key, data)
    end

    assert(data, ("bad argument #2 for 'data': expected table, got %s"):format(type(data)))

    cartridge._data[key] = data

    if cartridge._config.writeOnFlush then
        export_save()
    end
end

---Write a single value of data to the save data
---@param key string key to write to in the save data
---@param value any The data value to write for the key in the save data
function cartridge.write_value(key, value)
    assert(key and type(key) == "string", ("bad argument #1 for 'key': expected string, got %s"):format(type(key)))
    assert(value, "bad argument #2 for 'data': expected non-nil")

    cartridge._data[key] = value

    if cartridge._config.writeOnFlush then
        export_save()
    end
end

cartridge.save_all = export_save

return cartridge
