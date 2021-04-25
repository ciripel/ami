```md
# PUBLIC
am
    .execute(cliOrCmd, args)    
        - executes specified command with defined args
        - cmd defaults to am.__inteface
    
    .execute_extension(path, args?, options)
        - executes file as am extension providing access to all globals, am including
        - options:
            - contextFailExitCode: number 
            - partialErrorMsg: string - partial fallback error message, internal error is added to the end of this msg
            - errorMsg: string - fall back error message, internal error is not included
    
    .am.execute_external(command, args, injectArgs)
        - executes shell command
        - returns exit code

    .get_proc_args()
        - returns all args passed to ami process
        - e.g. for `ami setup --configure` returns `{ "setup", "--configure" }`

    .parse_args(cliOrCmd, args, options)
        - parses provided args or args passed to aplication if args not specified
        - relative to cliOrCmd with respect to specified options
        - cmd defaults to am.__inteface

    .print_help(cliOrCmd)
        - prints help of specified cliOrCmd
        - cmd defaults to am.__inteface

    .app
        .load_configuration()
        .load_model()
        .prepare()
        .render()
        .get_version()
        .get_type()
        .is_update_available()
        .remove_data()
        .remove()

        .get()                              - gets loaded value from app.h/json
        .get_configuration(key = nil, default)     - gets value from loaded config or config
        .get_model(key = nil, default)      - gets value from loaded config or config
        .set_model(newModel, path?, options: { merge = false, overwrite = true })
            - sets model or model value

    .cache
        .rm_pkgs()      - removes packages from cache
        .rm_plugins()   - removes plugins from cache
        .erase()        - removes everything from cache

    .plugin
        .get(id, version) - gets plugin from cache or downloads it
        .safe_get(id, version) - tryes to get plugin
            * returns true, plugin on success 
            * returns false, nil on failure


# INTERNALS
am
    .__parse_base_args() - parses default args
    .__reload_interface() - updates AMI reference (above) from ami.lua

    .app
        .__is_loaded()  - returns true if app config was loaded
    
# TEST_MODE:
am
    __set_interface(ami) - sets current am interface
    __reset_options() - resets am options

    .app
        .__get() - returns internal __APP
        .__set() - sets internal __APP
        .__set_loaded(value) - overwrites internal `set_loaded` states

    .plugin
        .__erase_cache()              - erases in mem plugin cache
        .__remove_cached(id, version) - removes all plugins from cache

TODO: consider possibility to drop dependency on posix/win32 fs api
```