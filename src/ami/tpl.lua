local _lustache = require "lustache"

function render_templates()
   log_info("Generating app templated files...")
   local _ok, _templates = eliFs.safe_read_dir(".ami-templates", {recurse = true, asDirEntries = true})
   if not _ok or #_templates == 0 then
      log_trace("No template found, skipping...")
      return
   end

   local _model = {}
   -- transform model object like tables to array tables
   for key, value in pairs(APP.model) do
      _model[key] = value
      if type(value) == "table" and not eliUtil.is_array(value) then
         _model[key .. "__ARRAY"] = eliUtil.to_array(value)
      end
   end

   local _configuration = {}
   -- transform configuration object like tables to array tables
   for key, value in pairs(APP.configuration) do
      _configuration[key] = value
      if type(value) == "table" and not eliUtil.is_array(value) then
         _configuration[key .. "__ARRAY"] = eliUtil.to_array(value)
      end
   end

   local _vm = {
      configuration = _configuration,
      model = _model,
      ROOT_DIR = eliProc.EPROC and eliProc.cwd() or ".",
      ID = APP.id,
      USER = APP.user
   }

   for _, entry in ipairs(_templates) do
      if entry:type() == "file" then
         local _templatePath = entry:fullpath()
         local _file = eliPath.file(_templatePath)
         local _pre, _suf = _file:match("(.*)%.template(.*)")
         local _renderedPath = eliPath.combine(eliPath.dir(eliPath.rel(_templatePath, ".ami-templates")), _pre .. _suf)

         log_trace("Rendering '" .. _templatePath .. "' to '" .. _renderedPath .. "'...")

         local _ok, _template = eliFs.safe_read_file(_templatePath)
         ami_assert(_ok, "Read failed for " .. _templatePath .. " - " .. (_template or ""), EXIT_TPL_READ_ERROR)
         local _result = _lustache:render(_template, _vm)

         local _ok, _error = eliFs.safe_mkdirp(eliPath.dir(_renderedPath))
         if _ok then
            _ok, _error = eliFs.safe_write_file(_renderedPath, _result)
         end

         ami_assert(_ok, "Write failed for " .. _templatePath .. " - " .. (_error or ""), EXIT_TPL_WRITE_ERROR)
         log_trace("'" .. _renderedPath .. "' rendered successfully.")
      end
   end
end
