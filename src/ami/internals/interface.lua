local _kindMap = {
    empty = require "ami.internals.interface.empty",
    base = require "ami.internals.interface.base",
    app = require "ami.internals.interface.app"
}

local function _new(kind, options)
    local _base = _kindMap[kind]
    if _base ~= nil then
        return _kindMap[kind].new(options)
    end
    -- try load from path if not cached
    local _ok, _new_base = pcall(loadfile, kind)
    ami_assert(_ok, "Base interface " .. (kind or "undefined") .. "not found!", EXIT_INVALID_AMI_BASE)
    local _ok, _base = pcall(_new_base, options)
    ami_assert(_ok, "Failed to load base interface - " .. (kind or "undefined") .. "!", EXIT_INVALID_AMI_BASE)
    -- recursively match all nested interfaces
    if type(_base.base) == "string" then
        _base = util.merge_tables(_new(_base.base, options), _base, true)
    end
    return _base
end

local function _load_interface(interfaceKind, shallow)
    log_trace("Loading app specific ami...")
    if not shallow then
        local _ok, _subAmiContent = fs.safe_read_file("ami.json")
        if _ok then
            log_trace("ami.json found loading...")
            _ok, _subAmi = pcall(hjson.parse, _subAmiContent)
            log_trace("ami.json load " .. (_ok and "successful" or "failed") .. "...")
        end

        if not _ok then
            _ok, _subAmiContent = fs.safe_read_file("ami.hjson")
            if _ok then
                log_trace("ami.hjson found loading...")
                _ok, _subAmi = pcall(hjson.parse, _subAmiContent)
                log_trace("ami.hjson load " .. (_ok and "successful" or "failed") .. "...")
            end
        end

        if not _ok then
            _ok, _subAmiContent = fs.safe_read_file("ami.lua")
            if _ok then
                log_trace("ami.lua found loading...")
                _, _subAmi = pcall(load, _subAmiContent)
                _ok, _subAmi = pcall(_subAmi)
                if _ok then
                    log_trace("ami.lua load successful...")
                else
                    log_trace("ami.lua load failed - " .. _subAmi)
                end
            end
        end
    end

    local _baseInterface

    if type(_subAmi) ~= "table" then
        _baseInterface = _new(interfaceKind or "app", {isLoaded = false})
        log_trace("App specific ami not found...")
        return false, _baseInterface
    else
        _baseInterface = _new(_subAmi.base or interfaceKind or "app", {isLoaded = true})
    end

    local _id = _baseInterface.id
    local _title = _subAmi.title
    if _subAmi.customTitle ~= true then
        _title = string.join_strings(" - ", "AMI", _subAmi.title)
    end

    local _result = util.merge_tables(_baseInterface, _subAmi, true)
    _result.id = _id
    _result.title = _title
    return true, _result
end

return {
    load = _load_interface,
    new = _new
}
