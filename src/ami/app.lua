local _amiPkg = require "ami.internals.pkg"
local _amiTpl = require "ami.internals.tpl"

local __APP = {}
local __model = {}
local __loaded = false
local __modelLoaded = false

local function _is_loaded()
    return __loaded
end

local function _set_loaded(value)
    __loaded = value
end

local function __set_app(app)
    __APP = app
end
local function __get_app()
    return __APP
end

local function _get(path, default)
    return table.get(__APP, path, default)
end

local function _get_config(path, default)
    if path ~= nil then
        return table.get(__APP.configuration or __APP.config, path, default)
    end
    local _result = __APP.configuration or __APP.config
    if _result == nil then
        return default
    end
    return _result
end

local function _load_model()
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

local function _get_model(path, default)
    if not __modelLoaded then
        _load_model()
    end
    if path ~= nil then
        return table.get(__model, path, default)
    end
    if __model == nil then
        return default
    end
    return __model
end

local function _set_model(value, path, options)
    if not __modelLoaded then
        _load_model()
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

local function _normalize_app_pkg_type(pkg)
    if type(pkg.type) == "string" then
        pkg.type = {
            id = pkg.type,
            repository = am.options.DEFAULT_REPOSITORY_URL,
            version = "latest"
        }
    end
    local _type = __APP.type
    ami_assert(type(_type) == "table", "Invalid pkg type!", EXIT_INVALID_PKG_TYPE)
    if type(_type.repository) ~= "string" then
        _type.repository = am.options.DEFAULT_REPOSITORY_URL
    end
end

local function _get_configuration_path()
    local _configurationCandidates = am.options.APP_CONFIGURATION_CANDIDATES
    for _, _cfgCandidate in ipairs(_configurationCandidates) do
        if fs.exists(_cfgCandidate) then
            return _cfgCandidate
        end
    end
    return nil
end

local function _load_config(path)
    local _configPath = type(path) == "string" and path or _get_configuration_path()
    if _configPath == nil then
        ami_error("Failed to locate app.h/json!", EXIT_INVALID_CONFIGURATION)
    end
    local _ok, _configContent = fs.safe_read_file(_configPath)
    if not _ok then
        ami_error("Failed to load app.h/json - " .. _configContent, EXIT_INVALID_CONFIGURATION)
    end
    _ok, __APP = pcall(hjson.parse, _configContent)
    if not _ok then
        ami_error("Failed to parse app.h/json - " .. __APP, EXIT_INVALID_CONFIGURATION)
    end
    __APP = hjson.parse(_configContent)
    _normalize_app_pkg_type(__APP)
    __loaded = true
end

local function _prepare_app()
    log_info("Preparing the application...")
    local _fileList, _modelInfo, _verTree = _amiPkg.prepare_pkg(__APP.type)

    _amiPkg.unpack_layers(_fileList)
    _amiPkg.generate_model(_modelInfo)
    fs.write_file(".version-tree.json", hjson.stringify_to_json(_verTree))
    _load_config()
end

local function _is_update_available()
    _normalize_app_pkg_type(__APP)

    local _ok, _verTreeJson = fs.safe_read_file(".version-tree.json", hjson.stringify_to_json(_verTree))
    if _ok then
        local _ok, _verTree = pcall(hjson.parse, _verTreeJson)
        if _ok then
            log_trace("Using .version-tree.json for update availability check.")
            return _amiPkg.is_pkg_update_available(_verTree)
        end
    end

    log_warn("Version tree not found. Running update check against specs...")
    local _ok, _specsFile = fs.safe_read_file("specs.json")
    ami_assert(_ok, "Failed to load app specs.json", EXIT_APP_UPDATE_ERROR)
    local _ok, _specs = pcall(hjson.parse, _specsFile)
    ami_assert(_ok, "Failed to parse app specs.json", EXIT_APP_UPDATE_ERROR)
    return _amiPkg.is_pkg_update_available(__APP.type, _specs.version)
end

local function _get_app_version()
    _normalize_app_pkg_type(__APP)

    local _ok, _verTreeJson = fs.safe_read_file(".version-tree.json", hjson.stringify_to_json(_verTree))
    if _ok then
        local _ok, _verTree = pcall(hjson.parse, _verTreeJson)
        if _ok then
            return _verTree.version
        end
    end
    log_warn("Version tree not found. Can not get the version...")
    return "unknown"
end

local function _get_type()
    if type(__APP.type) ~= "table" then
        return __APP.type
    end
    -- we want to get app type nicely formatted
    local _result = __APP.type.id
    if type(__APP.version) == "string" then
        _result = _result .. "@" .. _version
    end
    if type(__APP.repository) == "string" and __APP.repository ~= am.options.DEFAULT_REPOSITORY_URL then
        _result = _result .. "[" .. __APP.repository .. "]"
    end
    return _result
end

local function _remove_app_data()
    local _ok = fs.safe_remove("data", {recurse = true, contentOnly = true})
    ami_assert(_ok, "Failed to remove app data - " .. tostring(_error) .. "!", EXIT_RM_DATA_ERROR)
end

local _get_protected_files = function()
    local _protectedFiles = {}
    for _, configCandidate in ipairs(am.options.APP_CONFIGURATION_CANDIDATES) do
        _protectedFiles[configCandidate] = true
    end
    return _protectedFiles
end

local function _remove_app()
    local _ok, _files = fs.safe_read_dir(".", {recurse = true, returnFullPaths = true})
    ami_assert(_ok, "Failed to remove app - " .. (_error or "") .. "!", EXIT_RM_ERROR)
    local _protectedFiles = _get_protected_files()
    for i = 1, #_files do
        local _file = _files[i]

        if not _protectedFiles[path.file(_file)] then
            local _ok, _error = fs.safe_remove(_file)
            ami_assert(_ok, "Failed to remove '" .. _file .. "' - " .. tostring(_error) .. "!", EXIT_RM_ERROR)
        end
    end
end

return util.generate_safe_functions(
    {
        -- not yet decided whether get_config or get_configuration should persist
        load_config = _load_config,
        load_configuration = _load_config,
        load_model = _load_model,
        prepare = _prepare_app,
        render = _amiTpl.render_templates,
        get_version = _get_app_version,
        is_update_available = _is_update_available,
        remove_data = _remove_app_data,
        remove = _remove_app,
        get = _get,
        -- not yet decided whether get_config or get_configuration should persist
        get_config = _get_config,
        get_configuration = _get_config,
        get_model = _get_model,
        get_type = _get_type,
        set_model = _set_model,
        __is_loaded = _is_loaded,
        __set = TEST_MODE and __set_app,
        __get = TEST_MODE and __get_app,
        __set_loaded = TEST_MODE and _set_loaded
    }
)
