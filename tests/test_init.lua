elify()
hjson = util.generate_safe_functions(require"hjson")

TEST_MODE = true

local _packages = {
    "version-info", "ami.exit-codes", "ami.internals.util", "ami.internals.options.repository", "ami.internals.options.cache",
    "ami.internals.options.init", "ami.internals.interface.base", "ami.internals.interface.app", "ami.options", "ami.internals.exec",
    "ami.internals.cli", "ami.cache", "ami.internals.pkg", "ami.internals.tpl", "ami.app", "ami.plugin", "ami.internals.interface", 
    "ami.am", "ami.init"
}

return function()
    for _, v in ipairs(_packages) do
        local _pkgFromSrc = "src." .. v
        package.loaded[v] = nil
        package.loaded[_pkgFromSrc] = nil
        package.loaded[v] = require(_pkgFromSrc)
    end

    require"ami.init"()

    ami_error = function (msg)
        print(msg)
    end
end