local _join_strings = require "eli.extensions.string".join_strings

local _safe_extract = eliZip.safe_extract

local _safe_download_file = eliNet.safe_download_file
local _safe_hash_file = eliFs.safe_hash_file

local _parse_json = require "hjson".parse

PLUGIN_CACHE = PLUGIN_CACHE or {}

function load_plugin(name, options)
    if type(options) ~= "table" then
        options = {}
    end

    local _version = "latest"
    if type(options.version) == "string" then
        _version = "v/" .. options._version
    end
    local _pluginId = name .. "@" .. _version

    if type(PLUGIN_CACHE[_pluginId]) == "table" then
        log_trace("Loading plugin from cache...")
        return PLUGIN_CACHE[_pluginId]
    end
    log_trace("Plugin not cached, loading...")

    local _url = REPOSITORY_URL .. "plugin/" .. name .. "/" .. _version .. ".json"
    local _defFile = eliPath.combine(PLUGIN_DIR_DEFS, _pluginId)
    local _pluginDefinitionJson = ""
    if not eliFs.exists(_defFile) or _version == "latest" then
        log_trace("Defs not found, downloading...")
        local _ok, _error = _safe_download_file(_url, _defFile, {followRedirects = true})
        ami_assert(
            _ok,
            _join_strings("", "Failed to download ", _pluginId, " definition: ", _error),
            EXIT_PLUGIN_DOWNLOAD_ERROR
        )
    end

    local _ok, _file = eliFs.safe_read_file(_defFile)

    ami_assert(_ok, _join_strings("", "Failed to read ", _pluginId, " definition: ", _file), EXIT_PLUGIN_INVALID_DEFINITION)
    local _ok, _pluginDefinition = pcall(_parse_json, _file)
    ami_assert(_ok, _join_strings("", "Failed to parse ", _pluginId, " definition: ", _pluginDefinition), EXIT_PLUGIN_INVALID_DEFINITION)

    local _path = eliPath.combine(PLUGIN_DIR_ZIPS, _pluginId)
    local _downloadRequired = true
    if eliFs.exists(_path) then
        log_trace("Plugin package found, verifying...")
        local _ok, _hash = eliFs.safe_hash_file(_path, {hex = true})
        _downloadRequired = _hash:lower() ~= _pluginDefinition.sha256:lower()
        log_trace(
            not _downloadRequired and "Plugin package verified..." or
                "Plugin package verification failed, downloading... "
        )
    end

    if _downloadRequired then
        local _ok = _safe_download_file(_pluginDefinition.source, _path, {followRedirects = true})
        local _ok2, _hash = _safe_hash_file(_path, {hex = true})
        ami_assert(
            _ok and _ok2 and _hash:lower() == _pluginDefinition.sha256:lower(),
            "Failed to verify package integrity - " .. _pluginId .. "!",
            EXIT_PLUGIN_DOWNLOAD_ERROR
        )
    end

    local tmpfile = os.tmpname()
    os.remove(tmpfile)
    local _loadDir = tmpfile .. "_dir"

    local _ok, _error = eliFs.safe_mkdirp(_loadDir)
    ami_assert(_ok, _join_strings("", "Failed to create directory for plugin: ", _pluginId, " - ", _error), EXIT_PLUGIN_LOAD_ERROR)

    local _ok, _error = _safe_extract(_path, _loadDir, {flattenRootDir = true})
    ami_assert(_ok, _join_strings("", "Failed to extract plugin package: ", _pluginId, " - ", _error), EXIT_PLUGIN_LOAD_ERROR)

    local _entrypoint = name
    local _ok, _pluginSpecsJson = eliFs.safe_read_file(eliPath.combine(_loadDir, "specs.json"))
    if not _ok then
        _ok, _pluginSpecsJson = eliFs.safe_read_file(eliPath.combine(_loadDir, "specs.hjson"))
    end
    
    if _ok then 
        _ok, _pluginSpecs = pcall(_parse_json, _pluginSpecsJson)
        if _ok and type(_pluginSpecs.entrypoint) == 'string' then 
            _entrypoint = _pluginSpecs.entrypoint
        end
    end

    local _originalPath, _originalCPath = package.path, package.cpath
    package.path, package.cpath = _loadDir .. "/?.lua", _loadDir .. "/?.lua"

    local _ok, _result = pcall(require, _entrypoint)
    package.path, package.cpath = _originalPath, _originalCPath
    eliFs.remove(_loadDir, true)
    ami_assert(_ok, "Failed to require plugin: " .. _pluginId .. " - " .. (type(_result) == "string" and _result or ""), EXIT_PLUGIN_LOAD_ERROR)
    PLUGIN_CACHE[_pluginId] = _result
    return _result
end

function safe_load_plugin(...)
    return pcall(load_plugin, ...)
end