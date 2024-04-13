-- Copyright (C) 2024 alis.is

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.

-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local _amiBase = require"ami.internals.interface.base"

---Generates default tool interface
---@param options AmiCliGeneratorOptions
---@return ExecutableAmiCli
local function _new(options)
    if type(options) ~= "table" then
        options = {}
    end
    local _implementationStatus = not options.isAppAmiLoaded and "(not installed)" or "(not implemented)"
    local _implementationError = not options.isAppAmiLoaded and EXIT_NOT_INSTALLED or EXIT_NOT_IMPLEMENTED

    local function _violation_fallback()
        -- we falled in default interface... lets verify why
        local _ok, _entrypoint = am.__find_entrypoint()
        if not _ok then
            -- fails with proper error in case of entrypoint not found or invalid
            print("Failed to load entrypoint:")
            ami_error(_entrypoint --[[@as string]], EXIT_INVALID_AMI_INTERFACE)
        end
        -- entrypoint found and loadable but required action undefined
        ami_error("Violation of AMI@tool standard! " .. _implementationStatus, _implementationError)
    end

    local _base = _amiBase.new()
    _base.commands = {
        update = {
            index = 5,
            description = "ami 'update' command",
            summary = "Updates the tool or returns setup required",
            -- (options, command, args, cli)
            action = function()
                local _available, _id, _ver = am.app.is_update_available()
                if _available then
                    ami_error("Found new version " .. _ver .. " of " .. _id .. ", please run setup...", EXIT_SETUP_REQUIRED)
                end
                log_info("Tool is up to date.")
            end
        },
        remove = {
            index = 6,
            description = "ami 'remove' sub command",
            summary = "Remove the tool or parts based on options",
            options = {
                all = {
                    description = "Removes entire tool keeping only app.hjson"
                },
				force = {
					description = "Forces removal of application",
					hidden = true,
				}
            },
            -- (options, command, args, cli)
            action = function(_options)
				ami_assert(am.__has_app_specific_interface or _options.force, "You are trying to remove tool, but tool specific removal routine is not available. Use '--force' to force removal", EXIT_APP_REMOVE_ERROR)
				if _options.all then
                    am.app.remove()
                    log_success("Tool removed.")
                else
                    am.app.remove_data()
                    log_success("Tool data removed.")
                end
            end
        },
        about = {
            index = 7,
            description = "ami 'about' sub command",
            summary = _implementationStatus .. " Prints informations about the tool",
            -- (options, command, args, cli)
            action = _violation_fallback
        }
    }
    return _base --[[@as ExecutableAmiCli]]
end

return {
    new = _new
}
