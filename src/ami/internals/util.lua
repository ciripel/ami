local _util = {}

---Appends parts to url
---@param url string
---@vararg string
---@return any
function _util.append_to_url(url, ...)
    if type(url) == "string" then
        for _, _arg in ipairs(table.pack(...)) do
            if type(_arg) == "string" then
                url = path.combine(url, _arg)
            end
        end
    end
    return url
end


local function _replace_variables_recursively(content, variables)
	if type(variables) ~= "table" or util.is_array(variables) then
		return content
	end
	local _totalReplacementCount = 0
	for var, value in pairs(variables) do
		if not content:match("<.*>") then goto FINISH end

		if type(value) ~= "string" and type(value) ~= "number" then 
			log_warn("Invalid value of variable '" .. var .. "' detected: " .. tostring(value) .. "of type '" .. type(value) .. "'. Skipping...")
			goto CONTINUE
		end
		if type(value) == "string" and value:match("<" .. var .. ">") then 
			log_warn("Invalid value of variable '" .. var .. "' recursion detected: " .. tostring(value) .. "of type '" .. type(value) .. "'. Skipping...")
			goto CONTINUE
		end
		local _replacementCount = 0
		content, _replacementCount = content:gsub("<" .. var .. ">", value)
		_totalReplacementCount = _totalReplacementCount + _replacementCount
		::CONTINUE::
	end
	::FINISH::
	if _totalReplacementCount > 0 then
		return _replace_variables_recursively(content, variables)
	end
	return content
end

---Replaces variables in string
---@param content string
---@param variables table
---@return string
function _util.replace_variables(content, variables)
	if type(variables) ~= "table" or util.is_array(variables) then
		return content
	end

	for var, value in pairs(variables) do
		variables[var] = _replace_variables_recursively(value)
	end

	for var, value in pairs(variables) do
		if type(value) ~= "string" and type(value) ~= "number" then 
			log_warn("Invalid value of variable '" .. var .. "' detected: " .. tostring(value) .. "of type '" .. type(value) .. "'. Skipping...")
			goto CONTINUE
		end
		content = content:gsub("<" .. var .. ">", value)
		::CONTINUE::
	end
	return content
end

return _util