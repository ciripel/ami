local test = TEST or require "tests.vendor.u-test"

require"tests.test_init"

local _defaultCwd = os.cwd()

test["load valid ami"] = function()
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
	test.assert(_result == "test app")
end

test["load invalid ami"] = function()
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
	test.assert(_result:match("Failed to load entrypoint:"))
end

test["load valid ami violating app starndard"] = function()
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
	test.assert(_result:match("Violation of AMI@app standard!"))
end

if not TEST then
    test.summary()
end
