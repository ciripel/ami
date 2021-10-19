local _test = TEST or require "tests.vendor.u-test"

require"tests.test_init"
local _util = require "ami.internals.util"


_test["replace variables"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = "443"
	}

	local _configContent = _util.replace_variables([[{
		addr: "<ip>:<port>",
	}]], _variables)
	local _config = hjson.parse(_configContent)
	_test.assert(_config.addr == "127.0.0.1:443")
end

_test["replace variables (nested)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = "443",
		address = "<ip>:<port>"
	}

	local _configContent = _util.replace_variables([[{
		addr: "<address>",
	}]], _variables)
	local _config = hjson.parse(_configContent)
	_test.assert(_config.addr == "127.0.0.1:443")
end

_test["replace variables (numbers)"] = function()
	local _variables = {
		ip = "127.0.0.1",
		port = 443,
		address = "<ip>:<port>"
	}

	local _configContent = _util.replace_variables([[{
		addr: "<address>",
		port: <port>
	}]], _variables)
	local _config = hjson.parse(_configContent)
	_test.assert(type(_config.port) == "number" and _config.port == 443)
end 

_test["replace variables (cyclic - WARN expected)"] = function()
	local _variables = {
		ip = "<ip2>",
		ip2 = "<ip>"
	}
	local _configContent = _util.replace_variables([[{
		addr: "<ip2>",
		addr2: "<ip>"
	}]], _variables)
	local _config = hjson.parse(_configContent)
	_test.assert(_config.addr == "<ip2>" and _config.addr2 == "<ip2>")
end 

if not TEST then
    _test.summary()
end