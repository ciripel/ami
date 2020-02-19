local _eliFs = require "eli.fs"
local _eliPath = require "eli.path"
local _eliProc = require "eli.proc"

amalg = loadfile("./build/amalg.lua")

local function get_extensions()
    local _extensions = _eliFs.read_dir("ami")
    local _res = {}
    for _, _ext in  ipairs(_extensions) do
        table.insert(_res, "ami." .. _eliPath.nameext(_ext))
    end
    return table.unpack(_res)
end

_eliProc.chdir("src")
amalg("-o", "../bin/ami.lua", "-d", "-s", "amic.lua", get_extensions())--, get_extensions())
