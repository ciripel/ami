--[[
    Executes external action - (os.execute)
    @param {string} exec
    @param {String{}} args
    @param {boolean} readOutput
]]
local function _exec_external_action(exec, args, injectArgs)
    local _args = {}
    if type(injectArgs) == "table" then
        for _, v in ipairs(injectArgs) do
            if type(v) == "string" then
                table.insert(_args, v)
            end
        end
    end
    for _, v in ipairs(args) do
        table.insert(_args, v.arg)
    end
    if not proc.EPROC then
        local execArgs = ""
        for _, v in ipairs(args) do
            execArgs = execArgs .. ' "' .. v.arg:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"' -- add qouted string
        end
        local _result = proc.exec(exec .. " " .. execArgs)
        return _result.exitcode
    end
    local _result = proc.spawn(exec, _args, {wait = true, stdio = "ignore"})
    return _result.exitcode
end

--[[
    Executes native action - (lua file module)
    @param {string} modulePath
    @params {any{}} ...
]]
local function _exec_native_action(action, ...)
    if type(action) == "string" then
        return loadfile(action)(...)
    elseif type(action) == "function" then
        return action(...)
    else
        error("Unsupported action.code type!")
    end
end

--[[
    Executes extension - automatically wrapped lua file and handles exceptions
    @param {string} path
    @params {args{}} array of argumens
    @params {options{}}
]]
local function _exec_extension(path, args, options)
    if type(options) ~= "table" then
        if not util.is_array(args) then
            options = args
        else
            options = {}
        end
    end
    local _pastCtxExitCode = AMI_CONTEXT_FAIL_EXIT_CODE
    AMI_CONTEXT_FAIL_EXIT_CODE = options.contextFailExitCode
    local _ok, _ext = pcall(loadfile, path)
    if not _ok then
        ami_error("Failed to load extension from " .. path .. " - " .. (_ext or ""))
    end

    local _ok, _error = pcall(_ext, table.unpack(args))
    if not _ok then
        local _errMsg = "Execution of extension [" .. path .. "] failed - " .. (_error or "")
        if type(options.errorMsg) == "string" then
            _errMsg = options.errorMsg
        elseif type(options.partialErrorMsg) == "string" then
            _errMsg = options.partialErrorMsg .. " - " .. _error
        end
        ami_error(_errMsg)
    end
    AMI_CONTEXT_FAIL_EXIT_CODE = _pastCtxExitCode
end

return {
    extension = _exec_extension,
    external_action = _exec_external_action,
    native_action = _exec_native_action
}