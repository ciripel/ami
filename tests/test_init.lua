---@diagnostic disable: undefined-global, lowercase-global
hjson = util.generate_safe_functions(require"hjson")

TEST_MODE = true

local _originalCwd = os.cwd()
os.chdir("src")
require"am"

ami_error = function (msg)
    print(msg)
end

os.chdir(_originalCwd)