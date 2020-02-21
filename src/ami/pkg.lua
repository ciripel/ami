local _safe_download_file, _safe_download_string = eliNet.safe_download_file, eliNet.safe_download_string

local _safe_hash_file, _safe_read_file, _safe_write_file =
    eliFs.safe_hash_file,
    eliFs.safe_read_file,
    eliFs.safe_write_file

local _hjson = eliUtil.generate_safe_functions(require "hjson")

local function append_to_url(p, ...)
    if type(p) == "string" then
        for _, _arg in ipairs(table.pack(...)) do
            if type(_arg) == "string" then
                p = eliPath.combine(p, _arg)
            end
        end
    end
    return p
end

local function _normalize_app_pkg_type(pkg)
    if type(pkg.type) == "string" then
        pkg.type = {
            id = pkg.type,
            repository = "https://raw.githubusercontent.com/cryon-io/air/master/",
            version = "latest"
        }
    end
    ami_assert(type(APP.type) == "table", "Invalid pkg type!", EXIT_INVALID_PKG_TYPE)
    if type(APP.type.repository) ~= 'string' then 
        APP.type.repository = "https://raw.githubusercontent.com/cryon-io/air/master/"
    elseif APP.type.repository ~= "https://raw.githubusercontent.com/cryon-io/air/master/" then
        log_warn("Using external repository - " .. APP.type.repository)
    end
end

local function _normalize_pkg_type(pkgType)
    if pkgType.version == nil then
        pkgType.version = "latest"
    end
    ami_assert(type(pkgType.version) == "string", "Invalid pkg version", EXIT_INVALID_PKG_VERSION)
    if not pkgType.version:find(".json") then
        pkgType.version = pkgType.version .. ".json"
    end
    if type(pkgType.repository) ~= 'string' then
        pkgType.repository = "https://raw.githubusercontent.com/cryon-io/air/master/"
    end
end

local function _get_pkg_def(appType)
    local _pkgId = appType.id:gsub("%.", "/")
    local _defUrl = append_to_url(appType.repository, "definitions", _pkgId, appType.version)

    local _ok, _code, _pkgDefJson = _safe_download_string(_defUrl)
    log_trace("Downloading " .. appType.id .. " definition...")
    if not _ok or _code ~= 200 then
        log_trace("Failed to download " .. appType.id .. " definition. Looking for local copy...")
        local _ok, _pkgDefJson = _safe_read_file(eliPath.combine(CACHE_DIR_DEFS, appType.id))
        ami_assert(_ok, "Failed to download or load cached package definition... " , EXIT_PKG_INVALID_DEFINITION)
    else
        local _defLocalCopyPath = eliPath.combine(CACHE_DIR_DEFS, appType.id)
        _ok = _safe_write_file(_defLocalCopyPath, _pkgDefJson)
        if not _ok then
            -- it is not necessary to save definition locally as we hold version in memory already
            log_trace("Failed to create local copy of " .. appType.id .. " definition!")
        else
            log_trace("Local copy of " .. appType.id .. " definition saved into " .. _defLocalCopyPath)
        end
    end

    local _ok, _pkgDef = _hjson.safe_parse(_pkgDefJson)
    
    if not _ok then
        ami_error("Failed to parse package definition - " .. appType.id .. " - " .. _pkgDef, EXIT_PKG_INVALID_DEFINITION)
    end
    log_trace("Successfully parsed " .. appType.id .. " definition.")
    return _pkgDef
end

local function _get_pkg(pkgDef, options)
    if type(options) ~= "table" then
        options = {}
    end

    local _cachedPkgPath = eliPath.combine(CACHE_DIR, pkgDef.sha256)

    if options.noIntegrityChecks ~= true then
        local res, _hash = _safe_hash_file(_cachedPkgPath, {hex = true})
        if not res or _hash ~= pkgDef.sha256 then
            local _ok, _code = _safe_download_file(pkgDef.source, _cachedPkgPath, {followRedirects = true})
            ami_assert(_ok and _code == 200, "Failed to get package " .. (pkgDef.id or pkgDef.sha256), EXIT_PKG_DOWNLOAD_ERROR)
            _ok, _hash = _safe_hash_file(_cachedPkgPath, {hex = true})
        end
        ami_assert(_hash == pkgDef.sha256, "Failed to verify package integrity - " .. pkgDef.sha256 .. "!", EXIT_PKG_INTEGRITY_CHECK_ERROR)
        log_trace("Integrity checks of " .. pkgDef.sha256 .. " successful.")
    else
        log_trace("Integrity checks disabled. Skipping ... ")
    end

    return _cachedPkgPath
end

local function _get_pkg_specs(pkgPath)
    local _ok, _specsJson = eliZip.safe_extract_string(pkgPath, "specs.json", {flattenRootDir = true}) -- // TODO: specs not def
    
    ami_assert(_ok, "Failed to extract " .. pkgPath .. "", EXIT_PKG_LOAD_ERROR)
    if _specsJson == nil then 
        -- no specs, standalone package
        return {}
    end
    log_trace("Analyzing " .. pkgPath .. " specs...")
    
    local _ok, _specs = _hjson.safe_parse(_specsJson)
    if not _ok then
        ami_error("Failed to parse package specification - " .. pkgPath .. ' ' .. _specs, EXIT_PKG_LOAD_ERROR)
    end
    log_trace("Successfully parsed " .. pkgPath .. " specification.")
    return _specs
end

local function _prepare_pkg(appType, options)
    if type(appType.id) ~= "string" then
        ami_error("Invalid pkg specification or definition!", EXIT_PKG_INVALID_DEFINITION)
    end
    log_debug("Preparation of " .. appType.id .. " started ...")
    _normalize_pkg_type(appType)

    if type(options) ~= "table" then
        options = {}
    end

    local _pkgDef
    if type(SOURCES) == 'table' and SOURCES[appType.id] then 
        local _localSource = SOURCES[appType.id]
        log_trace("Loading local package from path " .. _localSource)
        local _tmp = eliPath.combine(CACHE_DIR, eliUtil.random_string(20))
        local _ok, _error = eliZip.safe_compress(_localSource, _tmp, { recurse = true, overwrite = true })
        ami_assert(_ok, "Failed to compress local source directory: " .. (_error or ""), EXIT_PKG_LOAD_ERROR)
        _ok, _hash = _safe_hash_file(_tmp, {hex = true})
        ami_assert(_ok, "Failed to load package from local sources", EXIT_PKG_INTEGRITY_CHECK_ERROR)
        os.rename(_tmp, eliPath.combine(CACHE_DIR, _hash))
        _pkgDef = { sha256 = _hash, id = 'debug-dir-pkg' }
    else 
        _pkgDef = _get_pkg_def(appType)
    end
    
    local _cachedPkgPath = _get_pkg(_pkgDef, options)

    local _specs = _get_pkg_specs(_cachedPkgPath)

    local _res = {}

    local _model = {model = nil, extensions = {}}
    if eliUtil.is_array(_specs.dependencies) then
        log_trace("Collection " .. appType.id .. " dependencies...")
        for _, dependency in pairs(_specs.dependencies) do
            log_trace("Collecting dependency " .. (type(dependency) == "table" and dependency.id or "n." .. _) .. "...")

            local _subRes, _subModel = _prepare_pkg(dependency)
            if type(_subModel.model) == "table" then
                -- we overwrite entire model with extension if we didnt get extensions only
                _model = _subModel
            else
                _model = eliUtil.merge_tables(_model, _subModel, true)
            end
            _res = eliUtil.merge_tables(_res, _subRes, true)
        end
        log_trace("Dependcies of " .. appType.id .. " successfully collected.")
    else
        log_trace("No dependencies specified by " .. appType.id .. " specification.")
    end

    log_trace("Preparing " .. appType.id .. " files...")
    local files = eliZip.get_files(_cachedPkgPath, {flattenRootDir = true})
    local _filter = function(k, v) -- ignore directories
        return type(v) == "string" and #v > 0 and not v:match("/$")
    end

    local _modelFound = false
    for _, file in ipairs(eliUtil.filter_table(files, _filter)) do
        -- assign file source
        if file == "model.lua" then
            _modelFound = true
            _model.model = {source = _pkgDef.sha256}
            _model.extensions = {}
        elseif file == "model.ext.lua" then
            if not _modelFound then -- we ignore extensions in same layer
                table.insert(_model.extensions, {source = _pkgDef.sha256})
            end
        elseif file ~= "model.ext.lua.template" and "model.ext.template.lua" then
            -- we do not accept templates for model as model is used to render templates :)
            _res[file] = {source = _pkgDef.sha256, id = appType.id, file = file}
        end
    end
    log_trace("Preparation of " .. appType.id .. " complete.")
    return _res, _model
end

local function _unpack_layers(fileList)
    local _unpackMap = {}
    local _unpackIdMap = {}
    for file, unpackInfo in pairs(fileList) do
        if type(_unpackMap[unpackInfo.source]) ~= "table" then
            _unpackMap[unpackInfo.source] = {[file] = unpackInfo.file}
        else
            _unpackMap[unpackInfo.source][file] = unpackInfo.file
        end
        _unpackIdMap[unpackInfo.source] = unpackInfo.id
    end

    for source, files in pairs(_unpackMap) do
        log_debug("Extracting (" .. source .. ") " .. _unpackIdMap[source])
        local _filter = function(f)
            return files[f]
        end

        local _transform = function(f, destination)
            local _name, _ext = eliPath.nameext(f)
            if _ext == "template" then
                destination = eliPath.combine(destination, ".ami-templates")
            else
                local _, _ext = eliPath.nameext(_name)
                if _ext == "template" then
                    destination = eliPath.combine(destination, ".ami-templates")
                end
            end

            return eliPath.combine(destination, files[f])
        end

        local _options = {flattenRootDir = true, filter = _filter, transform_path = _transform}
        local _ok, _error = eliZip.safe_extract(eliPath.combine(CACHE_DIR, source), ".", _options)
        ami_assert(_ok, _error, EXIT_PKG_LAYER_EXTRACT_ERROR)
        log_trace("(" .. source .. ") " .. _unpackIdMap[source] .. " extracted.")
    end
end

local function _generate_model(modelInfo)
    if type(modelInfo.model) ~= 'table' or type(modelInfo.model.source) ~= 'string' then 
        log_trace("No model found. Skipping model generation ...")
        return 
    end
    log_trace("Generating app model...")
    local _ok, _model = eliZip.safe_extract_string(eliPath.combine(CACHE_DIR, modelInfo.model.source), "model.lua", {flattenRootDir = true})
    if not _ok then 
        ami_error("Failed to extract app model - " .. _model .. "!", EXIT_PKG_MODEL_GENERATION_ERROR)
    end
    for _, ext in ipairs(modelInfo.extensions) do
        local _ok, _ext = eliZip.safe_extract_string(eliPath.combine(CACHE_DIR, ext.source), "model.ext.lua", {flattenRootDir = true})
        if not _ok then 
            ami_error("Failed to extract app model extension - " .. _ext .. "!", EXIT_PKG_MODEL_GENERATION_ERROR)
        end
        _model = _model .. '\n\n----------- injected ----------- \n--\t'.. ext.source .. '/model.ext.lua\n-------------------------------- \n\n' .. _ext
    end
    local _ok = _safe_write_file( "model.lua", _model)
    ami_assert(_ok, "Failed to write model.lua!", EXIT_PKG_MODEL_GENERATION_ERROR)
end

return {
    normalize_pkg_type = _normalize_app_pkg_type,
    prepare_pkg = _prepare_pkg,
    unpack_layers = _unpack_layers,
    generate_model = _generate_model
}