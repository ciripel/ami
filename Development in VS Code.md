To get autocomplete for eli std library you have to:
1. Install [Lua extension from sumneko](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
2. Download latest eli and ami meta definitions. 
   - `eli` meta definitions can be found in [eli releases](https://github.com/cryon-io/eli/releases) as meta.zip.
   - `ami` meta definitions can be found in [ami releases](https://github.com/cryon-io/ami/releases) as meta.zip.
3. Create directory where you want to store meta definitions. For this tutorial we assume `$HOME/lua/meta-definitions`.
4. Extract downloaded eli's `meta.zip` into `$HOME/lua/meta-definitions`
5. Rename meta directory for eli meta definitions - `$HOME/lua/meta-definitions/meta` -> `$HOME/lua/meta-definitions/eli`
6. Extract downloaded ami's `meta.zip` into `$HOME/lua/meta-definitions`
7. Rename meta directory for ami meta definitions - `$HOME/lua/meta-definitions/meta` -> `$HOME/lua/meta-definitions/ami`
8. In your project or workspace settings add:
```json
    ...,
    "Lua.workspace.library": [
        "$HOME/lua/meta-definitions/eli"
        "$HOME/lua/meta-definitions/ami"
    ],
    "Lua.diagnostics.globals": [
        "cli",
        "env",
        "fs",
        "hash",
        "Logger",
        "lz",
        "net",
        "path",
        "proc",
        "tar",
        "util",
        "ver",
        "zip"

        "am",
        "hjson",

        "log_success", 
        "log_trace", 
        "log_debug", 
        "log_info", 
        "log_warn", 
        "log_error",
        "ami_error",
        "ami_assert",

        "PLUGIN_IN_MEM_CACHE",
        "GLOBAL_LOGGER",
        
        "EXIT_SETUP_ERROR",
        "EXIT_NOT_INSTALLED",
        "EXIT_NOT_IMPLEMENTED",
        "EXIT_MISSING_API",
        "EXIT_ELEVATION_REQUIRED",
        "EXIT_SETUP_REQUIRED",
        "EXIT_UNSUPPORTED_PLATFORM",
        "EXIT_MISSING_PERMISSION",
        "EXIT_AMI_UPDATE_REQUIRED",
        "EXIT_INVALID_CONFIGURATION",
        "EXIT_INVALID_AMI_VERSION",
        "EXIT_INVALID_AMI_BASE_INTERFACE",
        "EXIT_APP_INVALID_MODEL",
        "EXIT_APP_DOWNLOAD_ERROR",
        "EXIT_APP_IO_ERROR",
        "EXIT_APP_UN_ERROR",
        "EXIT_APP_CONFIGURE_ERROR",
        "EXIT_APP_START_ERROR",
        "EXIT_APP_STOP_ERROR",
        "EXIT_APP_INFO_ERROR",
        "EXIT_APP_ABOUT_ERROR",
        "EXIT_APP_INTERNAL_ERROR",
        "EXIT_APP_UPDATE_ERROR",
        "EXIT_CLI_SCHEME_MISSING",
        "EXIT_CLI_ACTION_MISSING",
        "EXIT_CLI_ARG_VALIDATION_ERROR",
        "EXIT_CLI_INVALID_VALUE",
        "EXIT_CLI_INVALID_DEFINITION",
        "EXIT_CLI_CMD_UNKNOWN",
        "EXIT_CLI_OPTION_UNKNOWN",
        "EXIT_RM_ERROR",
        "EXIT_RM_DATA_ERROR",
        "EXIT_TPL_READ_ERROR",
        "EXIT_TPL_WRITE_ERROR",
        "EXIT_PLUGIN_DOWNLOAD_ERROR",
        "EXIT_PLUGIN_INVALID_DEFINITION",
        "EXIT_PLUGIN_LOAD_ERROR",
        "EXIT_PLUGIN_EXEC_ERROR",
        "EXIT_PKG_DOWNLOAD_ERROR",
        "EXIT_PKG_INVALID_DEFINITION",
        "EXIT_PKG_INVALID_VERSION",
        "EXIT_PKG_INVALID_TYPE",
        "EXIT_PKG_INTEGRITY_CHECK_ERROR",
        "EXIT_PKG_LOAD_ERROR",
        "EXIT_PKG_LAYER_EXTRACT_ERROR",
        "EXIT_PKG_MODEL_GENERATION_ERROR",
        "EXIT_INVALID_SOURCES_FILE",
        "EXIT_UNKNOWN_ERROR"
    ],
    ...
```
9. From now on you should get hints and autocomplete for eli stdlib and ami functions in this project/workspace.
