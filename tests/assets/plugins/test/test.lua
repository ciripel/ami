function _test() 
    return "cached test plugin"
end

function _version()
    return "0.0.1"
end

return {
    test = _test,
    version = _version
}