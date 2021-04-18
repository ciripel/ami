local _test = TEST or require "tests.vendor.u-test"

require"tests.test_init"

local stringify = require "hjson".stringify

local _defaultCwd = os.cwd()

_test["rm_pkgs & rm_plugins"] = function()
    am.__reset_options()
    fs.create_dir("tests/tmp/cache_partial_rm")
    am.options.CACHE_DIR = "tests/tmp/cache_partial_rm"

    fs.write_file(path.combine(am.options.CACHE_DIR_ARCHIVES, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_DIR_ARCHIVES, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_DIR_DEFS, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_DIR_DEFS, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_ARCHIVES, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_ARCHIVES, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_DEFS, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_DEFS, "test2"), "test2")

    am.cache.rm_pkgs()
    _test.assert(#fs.read_dir(am.options.CACHE_DIR_ARCHIVES) == 0)
    _test.assert(#fs.read_dir(am.options.CACHE_DIR_DEFS) == 0)

    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_ARCHIVES) ~= 0)
    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_DEFS) ~= 0)

    am.cache.rm_plugins()
    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_ARCHIVES) == 0)
    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_DEFS) == 0)
end


_test["erase"] = function()
    am.__reset_options()
    fs.create_dir("tests/tmp/cache_erase")
    am.options.CACHE_DIR = "tests/tmp/cache_erase"

    fs.write_file(path.combine(am.options.CACHE_DIR_ARCHIVES, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_DIR_ARCHIVES, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_DIR_DEFS, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_DIR_DEFS, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_ARCHIVES, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_ARCHIVES, "test2"), "test2")

    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_DEFS, "test1"), "test1")
    fs.write_file(path.combine(am.options.CACHE_PLUGIN_DIR_DEFS, "test2"), "test2")

    am.cache.erase()
    _test.assert(#fs.read_dir(am.options.CACHE_DIR_ARCHIVES) == 0)
    _test.assert(#fs.read_dir(am.options.CACHE_DIR_DEFS) == 0)
    
    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_ARCHIVES) == 0)
    _test.assert(#fs.read_dir(am.options.CACHE_PLUGIN_DIR_DEFS) == 0)
end

if not TEST then
    _test.summary()
end
