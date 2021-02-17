function _new()
    return {
        id = "ami",
        title = "AMI",
        partial = false,
        commandRequired = false,
        includeOptionsInUsage = true,
        commandsIndexed = true,
        optionsIndexed = true,
        options = {
            path = {
                index = 1,
                aliases = {"p"},
                description = "Path to app root folder",
                type = "string"
            },
            ["log-level"] = {
                index = 2,
                aliases = {"ll"},
                type = "string",
                description = "Log level - trace/debug/info/warn/error"
            },
            ["output-format"] = {
                index = 3,
                aliases = {"of"},
                type = "string",
                description = "Log format - json/standard"
            },
            ["cache"] = {
                index = 4,
                type = "string",
                description = "Path to cache directory or false for disable"
            },
            ["cache-timeout"] = {
                index = 5,
                type = "number",
                description = "Invalidation timeout of cached packages, definitions and plugins"
            },
            ["local-sources"] = {
                index = 6,
                aliases = {"ls"},
                type = "string",
                description = "Path to h/json file with local sources definitions"
            },
            version = {
                index = 7,
                aliases = {"v"},
                type = "boolean",
                description = "Prints AMI version"
            },
            about = {
                index = 8,
                type = "boolean",
                description = "Prints AMI about"
            },
            ["erase-cache"] = {
                index = 50,
                type = "boolean",
                description = "Removes all plugins and packages from cache.",
            },
            help = {
                index = 100,
                aliases = {"h"},
                description = "Prints this help message"
            },
            -- hidden
            ["no-integrity-checks"] = {
                index = 97,
                type = "boolean",
                description = "Disables integrity checks",
                hidden = true -- this is for debug purposes only, better to avoid
            },
            shallow = {
                index = 98,
                type = "boolean",
                description = "Prevents looking up and reloading app specific interface.",
                hidden = true -- this is non standard option
            },
            base = {
                index = 99,
                aliases = {"b"},
                type = "string",
                description = "Uses provided <base> as base interface for further execution",
                hidden = true -- for now we do not want to show this in help. For now intent is to use this in hypothetical ami wrappers
            }
        },
        action = function(_options, _command, _args)
            am.execute(_command, _args)
        end
    }
end

return {
    new = _new
}