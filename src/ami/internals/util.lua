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

return _util
