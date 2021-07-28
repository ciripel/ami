local _amiPkg = require "ami.internals.pkg"
local _amiTpl = require "ami.internals.tpl"

am.app = {}

---@type table
local __APP = {}
---@type table
local __model = {}
local __loaded = false
local __modelLoaded = false

---Returns true of app configuration is loaded
---@return boolean
function am.app.__is_loaded()
    return __loaded
end

if TEST_MODE then
    ---Sets internal state of app configuration being loaded
    ---@param value boolean
    function am.app.__set_loaded(value)
        __loaded = value
        __modelLoaded = value
    end

    ---Replaces loaded APP with app
    ---@param app table
    function am.app.__set(app)
        __APP = app
    end

    ---Returns loaded APP
    ---@return table
    function am.app.__get()
        return __APP
    end
end

---#DES am.app.get
---
---Gets valua from path in APP or falls back to default if value in path is nil
---@param path string
---@param default any
---@return any
function am.app.get(path, default)
    return table.get(__APP, path, default)
end

---#DES am.app.get_configuration
---
---Gets valua from path in app.configuration or falls back to default if value in path is nil
---@param path string
---@param default any
---@return any
function am.app.get_configuration(path, default)
    if path ~= nil then
        return table.get(__APP.configuration or __APP.config, path, default)
    end
    local _result = __APP.configuration or __APP.config
    if _result == nil then
        return default
    end
    return _result
end

---#DES am.app.get_config
---
---Gets valua from path in app.configuration or falls back to default if value in path is nil
---@deprecated
---@param path string
---@param default any
---@return any
function am.app.get_config(path, default)
    return am.app.get_configuration(path, default)
end

---#DES am.app.load_model
---
---Loads app model from model.lua
function am.app.load_model()
    local _path = "model.lua"
    log_trace("Loading application model...")
    if not fs.exists(_path) then
        return
    end
    __modelLoaded = true -- without this we would be caught in infinite recursion of loading model on demand
    local _ok, _error = pcall(dofile, _path)
    if not _ok then
        __modelLoaded = false
        ami_error("Failed to load app model - " .. _error, EXIT_APP_INVALID_MODEL)
    end
end

---#DES am.app.get_model
---
---Gets valua from path in app model or falls back to default if value in path is nil
---@param path string|string[]
---@param default any
---@return any
function am.app.get_model(path, default)
    if not __modelLoaded then
        am.app.load_model()
    end
    if path ~= nil then
        return table.get(__model, path, default)
    end
    if __model == nil then
        return default
    end
    return __model
end

---@class SetModelOptions
---@field overwrite boolean
---@field merge boolean

---#DES am.app.set_model
---
---Gets valua from path in app model or falls back to default if value in path is nil
---@param value any
---@param path string|string[]|SetModelOptions
---@param options SetModelOptions
function am.app.set_model(value, path, options)
    if not __modelLoaded then
        am.app.load_model()
    end

    if type(path) == "table" and not util.is_array(path) then
        options = path
        path = nil
    end
    if type(options) ~= "table" then
        options = {}
    end

    if path == nil then
        if options.merge then
            __model = util.merge_tables(__model, value, options.overwrite)
        else
            __model = value
        end
    else
        local _original = table.get(__model, path)
        if options.merge and type(_original) == "table" and type(value) == "table" then
            value = util.merge_tables(_original, value, options.overwrite)
        end
        table.set(__model, path, value)
    end
end

---Normalizes pkg type
---@param pkg table
local function _normalize_app_pkg_type(pkg)
    if type(pkg.type) == "string" then
        pkg.type = {
            id = pkg.type,
            repository = am.options.DEFAULT_REPOSITORY_URL,
            version = "latest"
        }
    end
    local _type = __APP.type
    ami_assert(type(_type) == "table", "Invalid pkg type!", EXIT_PKG_INVALID_TYPE)
    if type(_type.repository) ~= "string" then
        _type.repository = am.options.DEFAULT_REPOSITORY_URL
    end
end

---Looks up path to configuration file and retuns it
---@return string|nil
local function _get_configuration_path()
    local _configurationCandidates = am.options.APP_CONFIGURATION_CANDIDATES
    for _, _cfgCandidate in ipairs(_configurationCandidates) do
        if fs.exists(_cfgCandidate) then
            return _cfgCandidate
        end
    end
    return nil
end

---#DES am.app.load_configuration
---
---Loads APP from path
---@param path nil|string
function am.app.load_configuration(path)
    local _configPath = type(path) == "string" and path or _get_configuration_path()
    if _configPath == nil then
        ami_error("Failed to locate app.h/json!", EXIT_INVALID_CONFIGURATION)
    end
    local _ok, _configContent = fs.safe_read_file(_configPath)
    if not _ok then
        ami_error("Failed to load app.h/json - " .. _configContent, EXIT_INVALID_CONFIGURATION)
    end
    _ok, __APP = hjson.safe_parse(_configContent)
    if not _ok then
        ami_error("Failed to parse app.h/json - " .. __APP, EXIT_INVALID_CONFIGURATION)
    end
    __APP = hjson.parse(_configContent)
    _normalize_app_pkg_type(__APP)
    __loaded = true
end

---#DES am.app.load_config
---
---@deprecated
---Loads APP from path
---@param path nil|string
am.app.load_config = am.app.load_configuration

---#DES am.app.prepare
---
---Prepares app environment - extracts layers and builds model.
function am.app.prepare()
    log_info("Preparing the application...")
    local _fileList, _modelInfo, _verTree = _amiPkg.prepare_pkg(__APP.type)

    _amiPkg.unpack_layers(_fileList)
    _amiPkg.generate_model(_modelInfo)
    fs.write_file(".version-tree.json", hjson.stringify_to_json(_verTree))
    am.app.load_configuration()
end

---#DES am.app.render
---
---Renders app templates.
am.app.render = _amiTpl.render_templates

---#DES am.app.is_update_available
---
---Returns true if there is update available for any of related packages
---@return boolean
function am.app.is_update_available()
    _normalize_app_pkg_type(__APP)

    local _ok, _verTreeJson = fs.safe_read_file(".version-tree.json")
    if _ok then
        local _ok, _verTree = hjson.safe_parse(_verTreeJson)
        if _ok then
            log_trace("Using .version-tree.json for update availability check.")
            return _amiPkg.is_pkg_update_available(_verTree)
        end
    end

    log_warn("Version tree not found. Running update check against specs...")
    local _ok, _specsFile = fs.safe_read_file("specs.json")
    ami_assert(_ok, "Failed to load app specs.json", EXIT_APP_UPDATE_ERROR)
    local _ok, _specs = hjson.parse(_specsFile)
    ami_assert(_ok, "Failed to parse app specs.json", EXIT_APP_UPDATE_ERROR)
    return _amiPkg.is_pkg_update_available(__APP.type, _specs.version)
end

---#DES am.app.get_version
---
---Returns app version
---@return string|'"unknown"'
function am.app.get_version()
    _normalize_app_pkg_type(__APP)

    local _ok, _verTreeJson = fs.safe_read_file(".version-tree.json")
    if _ok then
        local _ok, _verTree = hjson.safe_parse(_verTreeJson)
        if _ok then
            return _verTree.version
        end
    end
    log_warn("Version tree not found. Can not get the version...")
    return "unknown"
end

---#DES am.app.get_type
---
---Returns app type
---@return string
function am.app.get_type()
    if type(__APP.type) ~= "table" then
        return __APP.type
    end
    -- we want to get app type nicely formatted
    local _result = __APP.type.id
    if type(__APP.version) == "string" then
        _result = _result .. "@" .. __APP.version
    end
    if type(__APP.type.repository) == "string" and __APP.type.repository ~= am.options.DEFAULT_REPOSITORY_URL then
        _result = _result .. "[" .. __APP.type.repository .. "]"
    end
    return _result
end

---#DES am.app.remove_data
---
---Removes content of app data directory
function am.app.remove_data()
    local _ok, _error = fs.safe_remove("data", {recurse = true, contentOnly = true})
    ami_assert(_ok, "Failed to remove app data - " .. tostring(_error) .. "!", EXIT_RM_DATA_ERROR)
end

local function _get_protected_files()
    local _protectedFiles = {}
    for _, configCandidate in ipairs(am.options.APP_CONFIGURATION_CANDIDATES) do
        _protectedFiles[configCandidate] = true
    end
    return _protectedFiles
end

---#DES am.app.remove
---
---Removes all app related files except app.h/json
function am.app.remove()
    local _ok, _files = fs.safe_read_dir(".", {recurse = true, returnFullPaths = true})
    if not _ok then
        ami_error("Failed to remove app - " .. (_files or "") .. "!", EXIT_RM_ERROR)
    end
    local _protectedFiles = _get_protected_files()
    for i = 1, #_files do
        local _file = _files[i]

        if not _protectedFiles[path.file(_file)] then
            local _ok, _error = fs.safe_remove(_file)
            ami_assert(_ok, "Failed to remove '" .. _file .. "' - " .. tostring(_error) .. "!", EXIT_RM_ERROR)
        end
    end
end
