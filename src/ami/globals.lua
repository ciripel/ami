require "ami.exit-codes"

hjson = util.generate_safe_functions(require "hjson")

---#DES log_success
---
---@param msg LogMessage|string
log_success,
---#DES log_trace
---
---@param msg LogMessage|string
log_trace,
---#DES log_debug
---
---@param msg LogMessage|string
log_debug,
---#DES log_info
---
---@param msg LogMessage|string
log_info,
---#DES log_warn
---
---@param msg LogMessage|string
log_warn,
---#DES log_error
---
---@param msg LogMessage|string
log_error = util.global_log_factory("ami", "success", "trace", "debug", "info", "warn", "error")

---@class AmiErrorOptions
---@field safe boolean

---#DES ami_error
---
---Raises ami error and exits ami with specified exit code unless safe is set to true
---@param msg string
---@param exitCode number
---@param options AmiErrorOptions|nil
ami_error = ami_error or function (msg, exitCode, options)
    log_error(msg)
    if type(options) == "table" and options.safe then
        return false
    end
    os.exit(exitCode or AMI_CONTEXT_FAIL_EXIT_CODE or EXIT_UNKNOWN_ERROR)
end

---#DES ami_assert
---
---Calls ami_error if result of the condition equals false
---@param msg string
---@param exitCode number
---@param options AmiErrorOptions|nil
function ami_assert(condition, msg, exitCode, options)
    if not condition then
        if exitCode == nil then
            exitCode = AMI_CONTEXT_FAIL_EXIT_CODE or EXIT_UNKNOWN_ERROR
        end
        return ami_error(msg, exitCode, options)
    end
    return true
end
