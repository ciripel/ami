---@diagnostic disable: undefined-global, lowercase-global
local _test = TEST or require "tests.vendor.u-test"
require"tests.test_init"

am.app.__set(
    {
        type = "test.app",
        configuration = {
            ip = "127.0.0.1",
            port = 80,
            name = "test"
        },
        user = "test"
    }
)

am.app.set_model(
    {
        DATA_DIR = "data",
        DAEMON_NAME = "testd"
    }
)

_test["get"] = function()
    _test.assert(am.app.get("type") == "test.app")
    _test.assert(am.app.get("type2", "unknown") == "unknown")
    _test.assert(am.app.get("type3") == nil)
    _test.assert(am.app.get("user", "test2") == "test")
end

_test["get_model"] = function()
    _test.assert(am.app.get_model("DATA_DIR") == "data")
    _test.assert(am.app.get_model("DATA_DIR2", "unknown") == "unknown")
    _test.assert(am.app.get_model("DATA_DIR3") == nil)
    _test.assert(am.app.get_model("DAEMON_NAME", "testd2") == "testd")
end

_test["get_config"] = function()
    _test.assert(am.app.get_configuration("ip") == "127.0.0.1")
    _test.assert(am.app.get_configuration("ip2", "unknown") == "unknown")
    _test.assert(am.app.get_configuration("ip3") == nil)
    _test.assert(am.app.get_configuration("name", "test2") == "test")
end

_test["load_configuration"] = function()
    am.app.__set_loaded(false)
    am.app.load_configuration("tests/assets/configs/load.hjson")
    _test.assert(am.app.get_configuration("ip") == "127.0.0.2")
end

_test["load_model"] = function()
    am.app.__set_loaded(false)
    local _cwd = os.cwd()
    os.chdir("tests/assets/models/load_model")
    _test.assert(am.app.get_model("DATA_DIR") == "test")
    os.chdir(_cwd)
end

_test["set_model"] = function()
    _test.assert(am.app.get_model("DATA_DIR") == "test")
    am.app.set_model("test2", "DATA_DIR")
    _test.assert(am.app.get_model("DATA_DIR") == "test2")
    am.app.set_model({DATA_DIR2 = "test3", DATA_DIR = "test3"}, { merge = true, overwrite = false })
    _test.assert(am.app.get_model("DATA_DIR") == "test2")
    _test.assert(am.app.get_model("DATA_DIR2") == "test3")
    am.app.set_model({DATA_DIR2 = "test3", DATA_DIR = "test3"}, { merge = true, overwrite = true })
    _test.assert(am.app.get_model("DATA_DIR") == "test3")
    _test.assert(am.app.get_model("DATA_DIR2") == "test3")
    am.app.set_model({DATA_DIR2 = "test3"}, { merge = false })
    _test.assert(am.app.get_model("DATA_DIR") == nil)
end

_test["nested base interfaces"] = function()
    -- // TODO
end

if not TEST then
    _test.summary()
end

