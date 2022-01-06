local _test = TEST or require "tests.vendor.u-test"

require"tests.test_init"

local _defaultCwd = os.cwd()

_test["load valid ami"] = function()
	os.chdir("tests/assets/interfaces/valid-ami")
	local _default_print = print
	local _result
	print = function(msg) 
		_result = msg
	end
	am.__reload_interface()
	am.execute("about")
	os.chdir(_defaultCwd)
	print = _default_print
	_test.assert(_result == "test app")
end

_test["load invalid ami"] = function()
	os.chdir("tests/assets/interfaces/invalid-ami")
	local _default_print = print
	local _result = ""
	print = function(msg) 
		_result = _result .. msg
	end
	am.__reload_interface()
	am.execute("about")
	os.chdir(_defaultCwd)
	print = _default_print
	_test.assert(_result:match("Failed to load entrypoint:"))
end

_test["load valid ami violating app starndard"] = function()
	os.chdir("tests/assets/interfaces/valid-ami-violating")
	local _default_print = print
	local _result
	print = function(msg) 
		_result = msg
	end
	am.__reload_interface()
	am.execute("about")
	os.chdir(_defaultCwd)
	print = _default_print
	_test.assert(_result:match("Violation of AMI standard!"))
end

if not TEST then
    _test.summary()
end
