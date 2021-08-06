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

---Replaces variables in string
---@param content string
---@param variables table
---@return string
function _util.replace_variables(content, variables)
	if type(variables) ~= "table" or util.is_array(variables) then
		return content
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