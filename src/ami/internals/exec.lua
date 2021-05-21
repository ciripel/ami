local exec = {}

---Executes external program with all arguments passed
---@param cmd string
---@param args CliArg[]
---@param injectArgs string[]
---@return integer
function exec.external_action(cmd, args, injectArgs)
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
        local _ok, _result = proc.safe_exec(cmd .. " " .. execArgs)
        ami_assert(_ok, "Failed to execute external action - " .. tostring(_result) .. "!")
        return _result.exitcode
    end
    local _ok, _result = proc.safe_spawn(cmd, _args, {wait = true, stdio = "ignore"})
    ami_assert(_ok, "Failed to execute external action - " .. tostring(_result) .. "!")
    return _result.exitcode
end

---@class ExecNativeActionOptions
---@field contextFailExitCode number
---@field errorMsg string|nil
---@field partialErrorMsg string|nil

---Executes native action - (lua file module)
---@param action string|function
---@param args CliArg[]|string[]
---@param options ExecNativeActionOptions
---@return any
function exec.native_action(action, args, options)
    if type(action) ~= "string" and  type(action) ~= "function" then
        error("Unsupported action/extension type (" .. type(action) .. ")!")
    end
    if type(args) ~= "table" then
        args = {}
    end
    if type(options) ~= "table" then
        if not util.is_array(args) then
            options = args
        else
            options = {}
        end
    end
    local _pastCtxExitCode = AMI_CONTEXT_FAIL_EXIT_CODE
    AMI_CONTEXT_FAIL_EXIT_CODE = options.contextFailExitCode
    local _id = table.get(options, "id",  table.get(options, "title", "unspecified"))
    if type(action) == "string" then
        local _ext, _error = loadfile(action)
        if type(_ext) ~= "function" then
            ami_error("Failed to load extension from " .. path .. " - " .. _error)
        end
        _id = action
        action = _ext
    end

    local _ok, _result = pcall(action, table.unpack(args))
    if not _ok then
        local _errMsg = "Execution of extension [" .. _id .. "] failed - " .. (tostring(_result) or "")
        if type(options.errorMsg) == "string" then
            _errMsg = options.errorMsg
        elseif type(options.partialErrorMsg) == "string" then
            _errMsg = options.partialErrorMsg .. " - " .. tostring(_result)
        end
        ami_error(_errMsg)
    end
    AMI_CONTEXT_FAIL_EXIT_CODE = _pastCtxExitCode
    return _result
end

return exec