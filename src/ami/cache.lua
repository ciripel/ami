am.cache = {}
---#DES am.cache.rm_pkgs
---
---Deletes content of package cache
function am.cache.rm_pkgs()
    fs.remove(am.options.CACHE_DIR_ARCHIVES, { recurse = true, contentOnly = true })
    fs.remove(am.options.CACHE_DIR_DEFS, { recurse = true, contentOnly = true })
end

---#DES am.cache.safe_rm_pkgs
---
---Deletes content of package cache
---@return boolean
function am.cache.safe_rm_pkgs() return pcall(am.cache.rm_pkgs) end

---#DES am.cache.rm_plugins
---
---Deletes content of plugin cache
function am.cache.rm_plugins()
    am.plugin.__erase_cache()
    fs.remove(am.options.CACHE_PLUGIN_DIR_ARCHIVES, { recurse = true, contentOnly = true })
    fs.remove(am.options.CACHE_PLUGIN_DIR_DEFS, { recurse = true, contentOnly = true })
end

---#DES am.cache.safe_rm_plugins
---
---Deletes content of plugin cache
---@return boolean
function am.cache.safe_rm_plugins() return pcall(am.cache.rm_plugins) end

---#DES am.cache.erase
---
---Deletes everything from cache
function am.cache.erase()
    am.cache.rm_pkgs()
    am.cache.rm_plugins()
end

---#DES am.cache.safe_erase
---
---Deletes everything from cache
---@return boolean
function am.cache.safe_erase() return pcall(am.cache.erase) end