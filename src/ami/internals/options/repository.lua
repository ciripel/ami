---@type AmiOptionsPlugin
local repOpts = {}

local DEFAULT_REPOSITORY_URL = "https://air.alis.is/ami/"

function repOpts.index(t, k)
	if k == "DEFAULT_REPOSITORY_URL" then
		return true, DEFAULT_REPOSITORY_URL
	end
	return false, nil
end

function repOpts.newindex(t, k, v)
	if k == "DEFAULT_REPOSITORY_URL" then
		DEFAULT_REPOSITORY_URL = v
		log_warn("Default repository set to third party repository - " .. tostring(v))
		return true
	end

	return false
end

return repOpts
