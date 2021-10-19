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

---Appends parts to url
---@param content string
---@param variables table
---@param cache table
---@param used table
---@return string, number
function _util.replace_variables(content, variables, cache, used)
	if type(used) ~= "table" then 
		used = {}
	end
	if type(cache) ~= "table" then 
		cache = {}
	end
	local _toReplace = {}

	for vid in content:gmatch("<(%S-)>") do
		if type(cache[vid]) == "string" then
			_toReplace["<" .. vid .. ">"] = cache[vid]
		elseif type(variables[vid]) == "string" then
			local _value = variables[vid]
			variables[vid] = nil
			used[vid] = true
			local _result = _util.replace_variables(_value, variables, cache, used)
			_toReplace["<" .. vid .. ">"] = _result
			cache[vid] = _result
			variables[vid] = _value
			used[vid] = nil
		elseif type(variables[vid]) == "number" then
			_toReplace["<" .. vid .. ">"] = variables[vid]
			cache[vid] = variables[vid]
		elseif used[vid] == true then
			log_warn("Cyclic variable reference detected '" .. tostring(vid) .. "'.")
		end
	end
	
	for k, v in pairs(_toReplace) do 
		content = content:gsub(k:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1"), v)
	end
	return content
end

return _util