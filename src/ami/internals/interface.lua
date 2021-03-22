local _kindMap = {
    base = require "ami.internals.interface.base",
    app = require "ami.internals.interface.app"
}

local function _new(kind, ...)
    return _kindMap[kind].new(...)
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
        _baseInterface = _new(_subAmi.kind or interfaceKind or "app", {isLoaded = true})
    end

    local _id = _baseInterface.id
    local _title = string.join_strings(" - ", _baseInterface.title, _subAmi.title)
    --[[ // TODO: expose base
        - recursively match and join interfaces
        - configurable base property in each ami
            - valua has to be type of string which is either key of cached ami
              or path to ami within app directory structure e.g. base="__<type>/ami.lua"
        ]]
    local _result = util.merge_tables(_baseInterface, _subAmi, true)
    _result.id = _id
    _result.title = _title
    return true, _result
end

return {
    load = _load_interface,
    new = _new
}
