local _cli = require"ami.internals.cli"
local _exec = require"ami.internals.exec"
local _interface = require"ami.internals.interface"
local util = require "ami.src.ami.internals.util"

local _amiArgs = {}
local _am

local function _execute(cmd, args)
    if util.is_array(cmd) then
        args = cmd
        cmd = _am.__interface
    end
    if type(cmd) == "string" and type(table.get(_am,{ "__interface", "commands" })) == "table" then
        cmd = _am.__interface.commands[cmd]
    end
    ami_assert(type(cmd) == "table", "No valid command provided!", EXIT_CLI_CMD_UNKNOWN)
    return _cli.process(cmd, args)
end

local function _get_proc_args()
    return util.clone(_amiArgs)
end

local function _parse_args(cmd, args, options)
    if util.is_array(cmd) then
        options = args
        args = cmd
        cmd = _am.__interface
    end
    if type(cmd) == "string" then
        cmd = _am.__interface[cmd]
    end
    return _cli.parse_args(args, cmd, options)
end

local function __parse_base_args(args, options)
    if type(options) ~= "table" then
        options = { stopOnCommand = true }
    end
    return _parse_args(_interface.new("base"), args, options)
end

local function _print_help(cmd, options)
    if not cmd then
        cmd = _am.__interface
    end
    if type(cmd) == "string" then
        cmd = _am.__interface[cmd]
    end
    return _cli.print_help(cmd, options)
end

local function __reload_interface(shallow)
    local _isAppSpecific, _amiInterface = _interface.load(_am.options.BASE_INTERFACE, shallow)
    _am.__interface = _amiInterface
    return _isAppSpecific
end

local function __set_interface(ami)
    _am.__interface = ami
end

_am = {
    cache = require"ami.cache",
    app = require"ami.app",
    options = require"ami.options",
    plugin = require"ami.plugin",
    execute = _execute,
    execute_extension = _exec.native_action,
    execute_external = _exec.external_action,
    get_proc_args = _get_proc_args,
    parse_args = _parse_args,
    print_help = _print_help,
    __parse_base_args = __parse_base_args,
    __reload_interface = __reload_interface,
    __set_interface = TEST_MODE and __set_interface
}

return function (...)
    _amiArgs = {...}
    return _am
end