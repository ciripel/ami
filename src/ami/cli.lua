local _eliUtil = require "eli.util"
local keys = _eliUtil.keys
--[[
    Parses value into required type if possible.
    @param {any} value 
    @param {string} _type
]]
local function parse_value(value, _type)
    if type(value) ~= "string" then
        return value
    end

    local _parse_map = {
        boolean = function(v)
            if v == "true" or v == "TRUE" or v == "True" then
                return true
            elseif v == "false" or v == "FALSE" or v == "False" then
                return false
            else
                ami_error("Invalid value type! Boolean expected, got: " .. value .. "!", EXIT_CLI_INVALID_VALUE)
            end
        end,
        number = function(v)
            local _res, _n = pcall(tonumber, v)
            if _res then
                return _n
            else
                ami_error("Invalid value type! Number expected, got: " .. value .. "!", EXIT_CLI_INVALID_VALUE)
            end
        end,
        string = function(v)
            return v
        end,
        auto = function(v)
            if v == "true" or v == "TRUE" or v == "True" then
                return true
            elseif v == "false" or v == "FALSE" or v == "False" then
                return false
            elseif v == "null" or v == "NULL" or v == "nil" then
                return nil
            else
                local _res, _n = pcall(tonumber, value)
                if _res then
                    return _n
                end
            end
            return v
        end
    }

    local _parse_fn = _parse_map[_type] or _parse_map.auto
    return _parse_fn(value)
end

--[[
    Executes external action - (os.execute)
    @param {string} exec
    @param {String{}} args
    @param {boolean} readOutput
]]
local function exec_external_action(exec, args, readOutput)
    local execArgs = ""
    for _, v in ipairs(args) do
        execArgs = execArgs .. ' "' .. v:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"' -- add qouted string
    end
    -- // TODO: for EPROC use 2 way pipe
    if readOutput then
        -- we have to return stdout and stderr
        local stderrFile = os.tmpname()
        local stdoutStream = io.popen(action.exec .. " " .. execArgs .. " 2>" .. stderrFile)
        local stdout = stdoutStream:read "a"
        -- lua does not support two way pipe by default so to keep stderr separeted it is
        -- redirected and read from temp file
        local stderrStream = io.popen(stderrFile)
        local stderr = stderrStream:read "a"
        stderrStream:close()
        return stdoutStream:close(), stdout, stderr
    else
        -- we are interested only in exit code
        return os.execute(action.exec .. " " .. execArgs)
    end
end

--[[
    Executes native action - (lua file module)
    @param {string} modulePath
    @params {any{}} ... 
]]
local function exec_native_action(action, ...)
    if type(action) == "string" then
        loadfile(action)(...)
    elseif type(action) == "table" then
        -- DEPRECATED
        log_warn("DEPRECATED: Code actions are deprecated and will be removed in future.")
        log_info("HINT: Consider defining action as function or usage of type 'native' pointing to lua file...")
        return exec_code_action(action.code, ...)
    elseif type(action) == "function" then
        action(...)
    else
        error("Unsupported action.code type!")
    end
end

--[[
    Executes code action - (lua code as string or function)
    @param {string|function} code
    @params {any{}} ... 
]]
local function exec_code_action(code, ...)
    if type(code) == "string" then
        return load(code)(...)
    elseif type(code) == "function" then
        return code(...)
    else
        error("Unsupported action.code type!")
    end
end

--[[ //TODO: update
    Generates optionList, parameterValues, command from args.
    @param {string{}} args
    @param {table{}} options
    @param {table{}} commands
]]
function parse_args(args, scheme, options)
    if not _eliUtil.is_array(args) then
        args = eliCli.parse_args()
    end

    if type(options) ~= "table" then
        options = {}
    end

    local _cliOptions = type(scheme.options) == "table" and scheme.options or {}
    local _cliCmds = type(scheme.commands) == "table" and scheme.commands or {}

    local _to_map = function(t)
        local _result = {}
        for k, v in pairs(t) do
            local _def = _eliUtil.merge_tables({id = k}, v)
            if type(v.aliases) == "table" then
                for j, a in ipairs(v.aliases) do
                    _result[a] = _def
                end
            end
            _result[k] = _def
        end
        return _result
    end

    local _cliOptionsMap = _to_map(_cliOptions)
    local _cliCmdMap = _to_map(_cliCmds)

    local _cliOptionList = {}
    local _cliRemainingArgs = {}
    local _cliCmd = nil

    local _lastIndex = 0
    for i = 1, #args, 1 do
        local _arg = args[i]
        if _arg.type == "option" then
            local _cliOptionDef = _cliOptionsMap[_arg.id]
            ami_assert(
                type(_cliOptionDef) == "table",
                "Unknown option - '" .. _arg.arg .. "'!",
                EXIT_CLI_OPTION_UNKNOWN
            )
            _cliOptionList[_cliOptionDef.id] = parse_value(_arg.value, _cliOptionDef.type)
        else
            if not options.ignoreCommands then
                _cliCmd = _cliCmdMap[_arg.arg]
                ami_assert(
                    type(_cliCmd) == "table",
                    "Unknown command '" .. (_arg.arg or "") .. "'!",
                    EXIT_CLI_CMD_UNKNOWN
                )
                _lastIndex = i + 1
            end
            break
        end
    end

    _remainingArgs = {table.unpack(args, _lastIndex)}
    return _cliOptionList, _cliCmd, _remainingArgs
end

--[[
    Validates processed args, whether there are valid in given cli definition
]]
local function default_validate_args(cli, optionList, command)
    local options = type(cli.options) == "table" and cli.options or {}
    local commands = type(cli.commands) == "table" and cli.commands or {}

    local _error = "Command not specified!"
    if cli.commandRequired and not command then
        return false, _error
    end

    for k, v in pairs(options) do
        if v and v.required then
            if not optionList[k] then
                return false, "Required option not specified! (" .. k .. ")"
            end
        end
    end
    return true
end

--[[
    Executes __cli__ definitions based on the args
    @param {table} cli
    @param {string{}} args
]]
function process_cli(cli, args)
    ami_assert(cli, "cli scheme not provided!", EXIT_CLI_SCHEME_MISSING)
    if args == nil then
        args = eliCli.parse_args()
    end

    local validate = type(cli.validate) == "function" and cli.validate or default_validate_args

    local cliId = cli.id and "(" .. cli.id .. ")" or ""
    local action = cli.action

    ami_assert(
        type(action) == "table" or type(action) == "function",
        "Action not specified properly or not found! " .. cliId,
        EXIT_CLI_ACTION_MISSING
    )

    if type(action) == "table" and action.type == "external" then
        return exec_external_action(action.exec, args, action.readOutput)
    end

    local optionList, command, remainingArgs = parse_args(args, cli)

    local _valid, _error = validate(cli, optionList, command)
    ami_assert(_valid, _error, EXIT_CLI_ARG_VALIDATION_ERROR)

    if type(command) == "table" then
        command.__cliId = cli.__cliId or cli.id
        command.__commandStack = cli.__commandStack or {}
        table.insert(command.__commandStack, command and command.id)
    end

    exec_native_action(action, optionList, command, remainingArgs, cli)
end

-- //TODO: handle usage generation for parent commands
local function generate_usage(cli, includeOptionsInUsage)
    local hasCommands = cli.commands and #keys(cli.commands)
    local hasOptions = cli.options and #keys(cli.options)

    local cliId = cli.__cliId or cli.id or eliPath.file(APP_ROOT_SCRIPT or "")
    local usage = "Usage: " .. cliId .. " "
    local optionalBegin = "["
    local optionalEnd = "]"

    for _, v in ipairs(cli.__commandStack or {}) do
        usage = usage .. v .. " "
    end

    if hasOptions and includeOptionsInUsage then
        for k, v in pairs(cli.options) do
            if v.aliases and v.aliases[1] and not v.hidden then
                local _begin = v.required and "" or optionalBegin
                local _end = v.required and "" or optionalEnd
                local optionAlias = v.aliases[1]
                if #optionAlias == 1 then
                    optionAlias = "-" .. optionAlias
                else
                    optionAlias = "--" .. optionAlias
                end
                usage = usage .. _begin .. optionAlias

                if v.type == "boolean" or v.type == nil then
                    usage = usage .. _end .. " "
                else
                    usage = usage .. "=<" .. k .. ">" .. _end .. " "
                end
            end
        end
    end

    if hasCommands then
        if cli.commandRequired then
            usage = usage .. "<command>" .. " "
        else
            usage = usage .. "[<command>]" .. " "
        end
    end
    return usage
end

local function are_all_hidden(t)
    for _, v in pairs(t) do
        if not v.hidden then
            return false
        end
    end
    return true
end

local function compare_args(t, a, b)
    if t[a].index and t[b].index then
        return t[a].index < t[b].index
    else
        return a < b
    end
end

local function generate_help_message(cli)
    local hasCommands = cli.commands and #keys(cli.commands) and not are_all_hidden(cli.commands)
    local hasOptions = cli.options and #keys(cli.options) and not are_all_hidden(cli.options)

    local rows = {}
    if hasOptions then
        table.insert(rows, {left = "Options: ", description = ""})
        local options = keys(cli.options)
        local sort_function = function(a, b)
            return compare_args(cli.options, a, b)
        end
        table.sort(options, sort_function)

        for _, k in ipairs(options) do
            local v = cli.options[k]
            _aliases = ""
            if v.aliases and v.aliases[1] and not v.hidden then
                for _, alias in ipairs(v.aliases) do
                    if #alias == 1 then
                        alias = "-" .. alias
                    else
                        alias = "--" .. alias
                    end
                    _aliases = _aliases .. alias .. "|"
                end

                _aliases = _aliases .. "--" .. k
                if v.type == "boolean" or v.type == nil then
                    _aliases = _aliases .. " "
                else
                    _aliases = _aliases .. "=<" .. k .. ">" .. " "
                end
            else
                _aliases = "--" .. k
            end
            table.insert(rows, {left = _aliases, description = v.description or ""})
        end
    end

    if hasCommands then
        table.insert(rows, {left = "", description = ""})
        table.insert(rows, {left = "Commands: ", description = ""})
        local commands = keys(cli.commands)
        local sort_function = function(a, b)
            return compare_args(cli.commands, a, b)
        end
        table.sort(commands, sort_function)

        for _, k in ipairs(commands) do
            local v = cli.commands[k]
            if not v.hidden then
                table.insert(rows, {left = k, description = v.summary or v.description or ""})
            end
        end
    end

    local leftLength = 0
    for _, row in ipairs(rows) do
        if #row.left > leftLength then
            leftLength = #row.left
        end
    end
    local newLine = eliPath.platform == "unix" and "\n" or "\r\n"
    local msg = ""
    for _, row in ipairs(rows) do
        if #row.left == 0 then
            msg = msg .. newLine
        else
            msg = msg .. row.left .. string.rep(" ", leftLength - #row.left) .. "\t\t" .. row.description .. newLine
        end
    end
    return msg
end

--[[
    Shows cli help
]]
function show_cli_help(cli, options)
    local title = options and options.title or cli.title
    local description = options and options.description or cli.description
    local includeOptionsInUsage = options and options.includeOptionsInUsage or cli.includeOptionsInUsage
    local printUsage = options and options.printUsage
    local footer = options and options.footer
    if printUsage == nil then
        printUsage = true
    end

    if type(cli.help_message) == "function" then
        print(cli.help_message(cli))
    elseif type(cli.help_message) == "string" then
        print(cli.help_message)
    else
        if OUTPUT_FORMAT == "json" then
            print(require "hjson".stringify(cli.commands, {invalidObjectsAsType = true, indent = false}))
        else
            -- collect and print help
            if title then
                print(title)
                print()
            end
            if description then
                print(description)
                print()
            end
            if printUsage then
                print(generate_usage(cli, includeOptionsInUsage))
                print()
            end
            print(generate_help_message(cli))
        end
    end
end
