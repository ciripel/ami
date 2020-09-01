local _test = TEST or require "tests.vendor.u-test"

require "src.ami.exit_codes"
require "src.ami.cli"
require "src.ami.util"
require "src.ami.init"
-- proxy ami.pkg from src.ami.pkg
package.loaded["ami.pkg"] = require "src.ami.pkg"
require "src.ami.app"

local stringify = require "hjson".stringify
local sha256sum = require "eli.hash".sha256sum

local _defaultCwd = eliProc.cwd()

_test["load app details (json)"] = function()
    APP = {}
    APP_CONFIGURATION_PATH = "app.json"
    eliProc.chdir("tests/app/app_details/1")
    local _ok = pcall(load_app_details)
    local _result = sha256sum(stringify(APP), {hex = true})
    eliProc.chdir(_defaultCwd)
    _test.assert(_result == "59ce504e40b90ae50c6b99567fd57186bad89939a1714c3335381eccf9fb1688")
end

_test["load app details (hjson)"] = function()
    old = stringify(APP)
    APP = {}
    APP_CONFIGURATION_PATH = "app.hjson"
    eliProc.chdir("tests/app/app_details/1")
    local _ok = pcall(load_app_details)
    local _result = sha256sum(stringify(APP), {hex = true})
    eliProc.chdir(_defaultCwd)
    _test.assert(_result == "59ce504e40b90ae50c6b99567fd57186bad89939a1714c3335381eccf9fb1688")
end

_test["load app details (inject model)"] = function()
    old = stringify(APP)
    APP = {}
    APP_CONFIGURATION_PATH = "app.json"
    eliProc.chdir("tests/app/app_details/2")
    local _ok = pcall(load_app_details)
    local _result = sha256sum(stringify(APP), {hex = true})
    eliProc.chdir(_defaultCwd)
    _test.assert(_result == "a39be4440996c688ff15e5b9c151a35d47cd419405662daffc587795d2f4bc2e")
end

_test["prepare app"] = function()
    set_cache_dir("tests/cache/2")
    local _testDir = "tests/tmp/app_test_prepare_app"
    eliFs.mkdirp(_testDir)
    eliFs.remove(_testDir, {recurse = true, contentOnly = true})

    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_testDir, "app.json"))
    _test.assert(_ok)
    eliProc.chdir(_testDir)

    local _ok = pcall(prepare_app)
    _test.assert(_ok)

    eliProc.chdir(_defaultCwd)
end

_test["get app version"] = function()
    set_cache_dir("tests/cache/2")
    local _testDir = "tests/tmp/app_test_get_app_version"
    eliFs.mkdirp(_testDir)
    eliFs.remove(_testDir, {recurse = true, contentOnly = true})

    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_testDir, "app.json"))
    _test.assert(_ok)
    eliProc.chdir(_testDir)

    local _ok = pcall(prepare_app)
    _test.assert(_ok)
    local _ok, _version = pcall(get_app_version)
    _test.assert(_ok and _version == "0.0.1")

    eliProc.chdir(_defaultCwd)
end

_test["remove app data"] = function()
    set_cache_dir("tests/cache/2")
    local _testDir = "tests/tmp/app_test_remove_app_data"
    eliFs.mkdirp(_testDir)
    eliFs.remove(_testDir, {recurse = true, contentOnly = true})
    local _dataDir = eliPath.combine(_testDir, "data")
    eliFs.mkdirp(_dataDir)

    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_testDir, "app.json"))
    _test.assert(_ok)
    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_dataDir, "app.json"))
    _test.assert(_ok)
    eliProc.chdir(_testDir)

    local _ok = pcall(prepare_app)
    _test.assert(_ok)
    local _ok = pcall(remove_app_data)
    _test.assert(_ok)
    local _ok, _entries = eliFs.safe_read_dir("data", {recurse = true})
    _test.assert(_ok and #_entries == 0)

    eliProc.chdir(_defaultCwd)
end

_test["remove app"] = function()
    set_cache_dir("tests/cache/2")
    local _testDir = "tests/tmp/app_test_remove_app"
    eliFs.mkdirp(_testDir)
    eliFs.remove(_testDir, {recurse = true, contentOnly = true})
    local _dataDir = eliPath.combine(_testDir, "data")
    eliFs.mkdirp(_dataDir)

    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_testDir, "app.json"))
    _test.assert(_ok)
    local _ok = eliFs.safe_copy_file("tests/app/configs/simple_test_app.json", eliPath.combine(_dataDir, "app.json"))
    _test.assert(_ok)
    eliProc.chdir(_testDir)

    local _ok = pcall(prepare_app)
    _test.assert(_ok)
    local _ok = pcall(remove_app)
    _test.assert(_ok)
    local _ok, _entries = eliFs.safe_read_dir(".", {recurse = true})
    local _nonDataEntries = {}
    for _, v in ipairs(_entries) do 
        if type(v) == "string" and not v:match("data/.*") then 
            table.insert(_nonDataEntries, v)
        end
    end
    _test.assert(_ok and #_entries == 3)

    eliProc.chdir(_defaultCwd)
end

if not TEST then
    _test.summary()
end
