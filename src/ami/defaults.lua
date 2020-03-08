REPOSITORY_URL = "https://raw.githubusercontent.com/cryon-io/air/master/"
AMI_VERSION = "0.0.6"
AMI_ABOUT = "AMI - Application Management Interface cli " .. AMI_VERSION .. " (C) 2020 cryon.io"

eliPath = require "eli.path"
eliFs = require "eli.fs"
eliProc = require "eli.proc"
eliCli = require "eli.cli"
eliNet = require "eli.net"
eliZip = require "eli.zip"
eliUtil = require "eli.util"
eliEnv = require "eli.env"
exString = require "eli.extensions.string"

local _hjson = require "hjson"
local _logger = require "eli.Logger":new()
GLOBAL_LOGGER = _logger
log_success, log_trace, log_debug, log_info, log_warn, log_error =
    require "eli.util".global_log_factory("ami", "success", "trace", "debug", "info", "warn", "error")

function set_cache_dir(path)
    CACHE_DIR = eliPath.combine(path, ".CACHE")
    CACHE_DIR_DEFS = eliPath.combine(CACHE_DIR, "definitions")

    eliFs.mkdirp(CACHE_DIR_DEFS)

    PLUGIN_DIR = eliPath.combine(CACHE_DIR, "plugins")
    PLUGIN_DIR_DEFS = eliPath.combine(PLUGIN_DIR, "defs")
    PLUGIN_DIR_ZIPS = eliPath.combine(PLUGIN_DIR, "zip")

    eliFs.mkdirp(PLUGIN_DIR_ZIPS)
    eliFs.mkdirp(PLUGIN_DIR_DEFS)
end

function ami_error(msg, exitCode)
    log_error(msg)
    os.exit(exitCode)
end

function ami_assert(condition, msg, exitCode)
    if not condition then
        ami_error(msg, exitCode)
    end
end

set_cache_dir("/var/cache/ami")

basicCliOptions = {
    path = {
        index = 1,
        aliases = {"p"},
        description = "Path to app root folder",
        type = "string"
    },
    ["log-level"] = {
        index = 2,
        aliases = {"ll"},
        type = "string",
        description = "Log level - trace/debug/info/warn/error"
    },
    ["output-format"] = {
        index = 3,
        aliases = {"of"},
        type = "string",
        description = "Log format - json/standard"
    },
    ["cache"] = {
        index = 4,
        type = "string",
        description = "Path to cache directory"
    },
    ["local-sources"] = {
        index = 5,
        aliases = {"ls"},
        type = "string",
        description = "Path to h/json file with local sources definitions"
    },
    version = {
        index = 6,
        aliases = {"v"},
        type = "boolean",
        description = "Prints AMI version"
    },
    about = {
        index = 6,
        type = "boolean",
        description = "Prints AMI about"
    },
    help = {
        index = 100,
        aliases = {"h"},
        description = "Prints this help message"
    }
}

local _parasedOptions = parse_args(_args, {options = basicCliOptions}, {strict = false, ignoreCommands = true})

if _parasedOptions["local-sources"] then
    local _ok, _localPkgsFile = eliFs.safe_read_file(_parasedOptions["local-sources"])
    ami_assert(_ok, "Failed to read local sources file " .. _parasedOptions["local-sources"], EXIT_INVALID_SOURCES_FILE)
    local _ok, _sources = pcall(_hjson.parse, _localPkgsFile)
    ami_assert(
        _ok,
        "Failed to parse local sources file " .. _parasedOptions["local-sources"],
        EXIT_INVALID_SOURCES_FILE
    )
    SOURCES = _sources
end

if _parasedOptions.path then
    if eliProc.EPROC then
        package.path = package.path .. ";" .. eliProc.cwd() .. "/?.lua"
        local _ok, _err = eliProc.safe_chdir(_parasedOptions.path)
        assert(_ok, _err)
    else
        log_error("Option 'path' provided, but chdir not supported.")
        log_info("HINT: Run ami without path parameter from path you supplied to 'path' option.")
        os.exit(1)
    end
end

-- load configuration
local _ok, _configJson = eliFs.safe_read_file("/etc/ami/ami.json")
if not _ok then
    _ok, _configJson = eliFs.safe_read_file("/etc/ami/ami.hjson")
end
if not _ok then
    _ok, _configJson = eliFs.safe_read_file("~/.ami/ami.json")
end
if not _ok then
    _ok, _configJson = eliFs.safe_read_file("~/.ami/ami.hjson")
end
if _ok then
    log_trace("Found configuration file, loading...")
    local _ok, _config = pcall(_hjson.parse, _configJson)
    if _ok then
        log_trace("Configuration successfully loaded...")
        if _config.CACHE_DIR then
            set_cache_dir(_config.CACHE_DIR)
        end
    end
end

if _parasedOptions.cache then
    set_cache_dir(_parasedOptions.cache)
end

if _parasedOptions["output-format"] then
    GLOBAL_LOGGER.options.format = _parasedOptions["output-format"]
    log_debug("Log format set to '" .. _parasedOptions["output-format"] .. "'.")
    if _parasedOptions["output-format"] == "json" then
        OUTPUT_FORMAT = "json"
    end
end

if _parasedOptions["log-level"] then
    GLOBAL_LOGGER.options.level = _parasedOptions["log-level"]
    log_debug("Log level set to '" .. _parasedOptions["log-level"] .. "'.")
end

if not eliFs.exists("app.hjson") and not eliFs.exists("app.hjson") then
    -- we are working without app configuration, expose default options
    if _parasedOptions.version then
        print(AMI_VERSION)
        os.exit(EXIT_INVALID_CONFIGURATION)
    end
    if _parasedOptions.about then
        print(AMI_ABOUT)
        os.exit(EXIT_INVALID_CONFIGURATION)
    end
end
