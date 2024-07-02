local test = TEST or require "tests.vendor.u-test"

require"tests.test_init"

test["replace variables"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = "443"
	}

	local _configContent = am.util.replace_variables([[{
		addr: "<ip>:<port>",
	}]], _variables)
	local _config = hjson.parse(_configContent)
	test.assert(_config.addr == "127.0.0.1:443")
end

test["replace variables (nested)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = "443",
		address = "<ip>:<port>"
	}

	local _configContent = am.util.replace_variables([[{
		addr: "<address>",
	}]], _variables)
	local _config = hjson.parse(_configContent)
	test.assert(_config.addr == "127.0.0.1:443")
end

test["replace variables (numbers)"] = function()
	local variables = {
		ip = "127.0.0.1",
		port = 443,
		address = "<ip>:<port>"
	}

	local configContent = am.util.replace_variables([[{
		addr: "<address>",
		port: <port>
	}]], variables)
	local config = hjson.parse(configContent)
	test.assert(type(config.port) == "number" and config.port == 443)
end 

test["replace variables (cyclic - WARN expected)"] = function()
	local _variables = {
		ip = "<ip2>",
		ip2 = "<ip>"
	}
	local _configContent = am.util.replace_variables([[{
		addr: "<ip2>",
		addr2: "<ip>"
	}]], _variables)
	local _config = hjson.parse(_configContent)
	test.assert(_config.addr == "<ip2>" and _config.addr2 == "<ip2>")
end 

test["replace variables (with mustache)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = 443,
		address = "<ip>:<port>"
	}

	local _configContent = am.util.replace_variables([[{
		addr: "{{{address}}}",
		port: <port>
	}]], _variables)
	local _config = hjson.parse(_configContent)
	test.assert(type(_config.port) == "number" and _config.port == 443)
end

test["replace variables (only mustache)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = 443,
		address = "127.0.0.1:443"
	}

	local _configContent = am.util.replace_variables([[{
		addr: "{{{address}}}",
		port: <port>
	}]], _variables, { replaceArrow = false })
	local _config = hjson.parse(_configContent)
	test.assert(_config.addr == "127.0.0.1:443" and _config.port == "<port>")
end


test["replace variables (only arrow)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = 443,
		address = "127.0.0.1:443"
	}

	local _configContent = am.util.replace_variables([[{
		addr: "{{{address}}}",
		port: <port>
	}]], _variables, { replaceMustache = false })
	local _config = hjson.parse(_configContent)
	test.assert(_config.addr == "{{{address}}}" and _config.port == 443)
end

if not TEST then
    test.summary()
end
