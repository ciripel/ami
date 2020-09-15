local _join_strings = require "eli.extensions.string".join_strings

local _safe_extract = eliZip.safe_extract

local _safe_download_file, _safe_download_string = eliNet.safe_download_file, eliNet.safe_download_string
local _safe_hash_file, _safe_read_file, _safe_write_file =
    eliFs.safe_hash_file,
    eliFs.safe_read_file,
    eliFs.safe_write_file

local _hjson = eliUtil.generate_safe_functions(require "hjson")

PLUGIN_IN_MEM_CACHE = PLUGIN_IN_MEM_CACHE or {}

function _get_plugin_def(name, version)
    local _pluginId = name .. "@" .. version

    if version == "latest" then
        _defUrl = append_to_url(REPOSITORY_URL, "plugin", name, version .. ".json")
    else
        _defUrl = append_to_url(REPOSITORY_URL, "plugin", name, "v", version .. ".json")
    end
    local _defLocalPath = eliPath.combine(CACHE_PLUGIN_DIR_DEFS, _pluginId)
    if CACHE_DISABLED ~= true then
        local _ok, _pluginDefJson = _safe_read_file(_defLocalPath)
        if _ok then
            local _ok, _pluginDef = _hjson.safe_parse(_pluginDefJson)
            if
                _ok and
                    (version ~= "latest" or
                        (type(_pluginDef.lastAmiCheck) == "number" and
                            _pluginDef.lastAmiCheck + AMI_CACHE_TIMEOUT > os.time()))
             then
                return _pluginDef
            end
        end
    end

    local _ok, _pluginDefJson = _safe_download_string(_defUrl)
    ami_assert(
        _ok,
        _join_strings("", "Failed to download ", _pluginId, " definition: ", _error),
        EXIT_PLUGIN_INVALID_DEFINITION
    )
    local _ok, _pluginDef = _hjson.safe_parse(_pluginDefJson)
    ami_assert(
        _ok,
        _join_strings("", "Failed to parse ", _pluginId, " definition: ", _pluginDefinition),
        EXIT_PLUGIN_INVALID_DEFINITION
    )

    if CACHE_DISABLED ~= true then
        local _cachedDef = eliUtil.merge_tables(_pluginDef, {lastAmiCheck = os.time()})
        local _ok, _pluginDefJson = _hjson.safe_stringify(_cachedDef)
        _ok = _ok and _safe_write_file(_defLocalPath, _pluginDefJson)
        if _ok then
            log_trace("Local copy of " .. _pluginId .. " definition saved into " .. _defLocalPath)
        else
            -- it is not necessary to save definition locally as we hold version in memory already
            log_trace("Failed to create local copy of " .. _pluginId .. " definition!")
        end
    end

    log_trace("Successfully parsed " .. _pluginId .. " definition.")
    return _pluginDef
end

function load_plugin(name, options)
    if type(options) ~= "table" then
        options = {}
    end

    local _version = "latest"
    if type(options.version) == "string" then
        _version = options.version
    end
    local _pluginId = name .. "@" .. _version

    if type(PLUGIN_IN_MEM_CACHE[_pluginId]) == "table" then
        log_trace("Loading plugin from cache...")
        return PLUGIN_IN_MEM_CACHE[_pluginId]
    end
    log_trace("Plugin not loaded, loading...")

    local _pluginDefinition = _get_plugin_def(name, _version)

    local _cachedArchivePath = eliPath.combine(CACHE_PLUGIN_DIR_ARCHIVES, _pluginId)
    local _downloadRequired = true
    if eliFs.exists(_cachedArchivePath) then
        log_trace("Plugin package found, verifying...")
        local _ok, _hash = _safe_hash_file(_cachedArchivePath, {hex = true})
        _downloadRequired = not _ok or _hash:lower() ~= _pluginDefinition.sha256:lower()
        log_trace(
            not _downloadRequired and "Plugin package verified..." or
                "Plugin package verification failed, downloading... "
        )
    end

    if _downloadRequired then
        local _ok = _safe_download_file(_pluginDefinition.source, _cachedArchivePath, {followRedirects = true})
        local _ok2, _hash = _safe_hash_file(_cachedArchivePath, {hex = true})
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
    ami_assert(
        _ok,
        _join_strings("", "Failed to create directory for plugin: ", _pluginId, " - ", _error),
        EXIT_PLUGIN_LOAD_ERROR
    )

    local _ok, _error = _safe_extract(_cachedArchivePath, _loadDir, {flattenRootDir = true})
    ami_assert(
        _ok,
        _join_strings("", "Failed to extract plugin package: ", _pluginId, " - ", _error),
        EXIT_PLUGIN_LOAD_ERROR
    )

    local _entrypoint = name .. ".lua"
    local _ok, _pluginSpecsJson = _safe_read_file(eliPath.combine(_loadDir, "specs.json"))
    if not _ok then
        _ok, _pluginSpecsJson = _safe_read_file(eliPath.combine(_loadDir, "specs.hjson"))
    end

    if _ok then
        _ok, _pluginSpecs = _hjson.safe_parse(_pluginSpecsJson)
        if _ok and type(_pluginSpecs.entrypoint) == "string" then
            _entrypoint = _pluginSpecs.entrypoint
        end
    end

    local _originalCwd = eliProc.cwd()

    -- plugins used in non EPROC should be used compiled as single lue file. Requiring sub files from plugin dir wont be available.
    if eliProc.EPROC then
        eliProc.safe_chdir(_loadDir)
    end
    local _ok, _result = pcall(dofile, _entrypoint)
    eliFs.safe_remove(_loadDir, { recurse = true })
    ami_assert(
        _ok,
        "Failed to require plugin: " .. _pluginId .. " - " .. (type(_result) == "string" and _result or ""),
        EXIT_PLUGIN_LOAD_ERROR
    )
    if eliProc.EPROC then
        local _ok = eliProc.safe_chdir(_originalCwd)
        ami_assert(_ok, "Failed to chdir after plugin load", EXIT_PLUGIN_LOAD_ERROR)
    end
    PLUGIN_IN_MEM_CACHE[_pluginId] = _result
    return _result
end

function safe_load_plugin(...)
    return pcall(load_plugin, ...)
end
