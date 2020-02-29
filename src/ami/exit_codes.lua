local _exitCodes = {
    EXIT_SETUP_ERROR = 1,
    EXIT_NOT_INSTALLED = 2,
    EXIT_NOT_IMPLEMENTED = 3,
    EXIT_MISSING_API = 4,
    EXIT_ELEVATION_REQUIRED = 5,
    EXIT_SETUP_REQUIRED = 6,
    EXIT_UNSUPPORTED_PLATFORM = 7,
    EXIT_MISSING_PERMISSION = 8,

    EXIT_INVALID_CONFIGURATION = 10,

    EXIT_APP_INVALID_MODEL = 20,
    EXIT_APP_DOWNLOAD_ERROR = 21,
    EXIT_APP_IO_ERROR = 22,
    EXIT_APP_UN_ERROR = 23,
    EXIT_APP_CONFIGURE_ERROR = 24,
    EXIT_APP_START_ERROR = 25,
    EXIT_APP_STOP_ERROR = 26,
    EXIT_APP_INFO_ERROR = 27,
    EXIT_APP_ABOUT_ERROR = 28,
    EXIT_APP_INTERNAL_ERROR = 29,
    EXIT_APP_UPDATE_ERROR = 30,

    
    EXIT_CLI_SCHEME_MISSING = 35,
    EXIT_CLI_ACTION_MISSING = 36,
    EXIT_CLI_ARG_VALIDATION_ERROR = 37,
    EXIT_CLI_INVALID_VALUE = 38,

    EXIT_CLI_CMD_UNKNOWN = 40,
    EXIT_CLI_OPTION_UNKNOWN = 41, 

    EXIT_RM_ERROR = 51,
    EXIT_RM_DATA_ERROR = 52,

    EXIT_TPL_READ_ERROR = 70,
    EXIT_TPL_WRITE_ERROR = 71,

    EXIT_PLUGIN_DOWNLOAD_ERROR = 80,
    EXIT_PLUGIN_INVALID_DEFINITION = 81,
    EXIT_PLUGIN_LOAD_ERROR = 82,


    EXIT_PKG_DOWNLOAD_ERROR = 90,
    EXIT_PKG_INVALID_DEFINITION = 91,
    EXIT_PKG_INVALID_VERSION = 92,
    EXIT_PKG_INVALID_TYPE = 93,
    EXIT_PKG_INTEGRITY_CHECK_ERROR = 94,
    EXIT_PKG_LOAD_ERROR = 95,
    EXIT_PKG_LAYER_EXTRACT_ERROR = 96,
    EXIT_PKG_MODEL_GENERATION_ERROR = 97,

    EXIT_INVALID_SOURCES_FILE = 99
    -- 100 - 150 reserved for unit
}

for k,v in pairs(_exitCodes) do 
    _G[k] = v 
end

return _exitCodes