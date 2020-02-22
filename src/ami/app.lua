local hjson = require "hjson"
local _amiPkg = require "ami.pkg"

local function _inject_mdl()
    _path = "model.lua"
    if eliFs.exists(_path) then
        local _ok, _error = pcall(dofile, "model.lua")
        if not _ok then 
            ami_error("Failed to load app model - " .. _error, EXIT_APP_INVALID_MODEL)
        end
    end
    return APP.model 
end

function load_app_details()
    _path = "app.hjson"
    if not eliFs.exists(_path) then
        _path = "app.json"
    end
    local _ok, _configContent = eliFs.safe_read_file(_path)
    if _ok then 
        _ok, APP = pcall(hjson.parse, _configContent)
        if not _ok then 
            ami_error("Failed to load app.json - " .. APP, EXIT_INVALID_CONFIGURATION)
        end
        log_trace("Injecting APP.model...")
        _inject_mdl()
        
        local _model = APP.model
        APP = hjson.parse(_configContent)
        APP.model = _model
    else 
        ami_error("Failed to load app.json - " .. _configContent, EXIT_INVALID_CONFIGURATION)
    end
end

function prepare_app()
    log_info("Preparing the application...")
    _amiPkg.normalize_pkg_type(APP)
    local _fileList, _modelInfo = _amiPkg.prepare_pkg(APP.type)
    _amiPkg.unpack_layers(_fileList)
    _amiPkg.generate_model(_modelInfo)
    load_app_details()
end

function remove_app_data()
    local _ok, _paths = eliFs.safe_read_dir("data", {recurse = true, returnFullPaths = true})
    if not _ok then 
        return -- dir does not exist
    end
    for _, path in ipairs(_paths) do 
        local _ok, _error = eliFs.safe_remove(path)
        ami_assert(_ok, "Failed to remove app data - " .. tostring(_error) .. "!", EXIT_RM_DATA_ERROR)
    end
end

local _protectedFiles = {
    ["app.hjson"] = true,
    ["app.json"] = true
}

function remove_app()
    local _ok, _files = eliFs.safe_read_dir(".", {recurse = true, returnFullPaths = true})
    ami_assert(_ok, "Failed to remove app - " .. (_error or "") .. "!", EXIT_RM_ERROR)
    for i=1, #_files do 
        local _file = _files[i]

        if not _protectedFiles[eliPath.file(_file)] then
            local _ok, _error = eliFs.safe_remove(_file)
            ami_assert("Failed to remove '" .. _file .. "' - " .. tostring(_error) .. "!", EXIT_RM_ERROR)
        end
    end
end 