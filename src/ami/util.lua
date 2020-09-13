function append_to_url(p, ...)
    if type(p) == "string" then
        for _, _arg in ipairs(table.pack(...)) do
            if type(_arg) == "string" then
                p = eliPath.combine(p, _arg)
            end
        end
    end
    return p
end

function cleanup_pkg_cache()
    eliFs.safe_remove(CACHE_DIR_ARCHIVES, { recurse = true, contentOnly = true })
    eliFs.safe_remove(CACHE_DIR_DEFS, { recurse = true, contentOnly = true })
end

function cleanup_plugin_cache()
    eliFs.safe_remove(CACHE_PLUGIN_DIR_ARCHIVES, { recurse = true, contentOnly = true })
    eliFs.safe_remove(CACHE_PLUGIN_DIR_DEFS, { recurse = true, contentOnly = true })
end

function cleanup_cache()
    cleanup_pkg_cache()
    cleanup_plugin_cache()
end