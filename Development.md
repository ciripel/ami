To develop AMI based applications you do not need access to AIR repository nor internet connectivity. 

## Environment Preparation

1. install `ami` and `eli`
    * `wget https://raw.githubusercontent.com/cryon-io/ami/master/install.sh -O /tmp/install.sh && sh /tmp/install.sh`
2. prepare directories for layers you want to develop
    *  Lets say you want to develop/improve `etho.node` and `etho.binaries` layers 
    *  Create directories for your layers e.g.: `mkdir -p ~/ami/etho.binaries ~/ami/etho.node`
3. create source mapping for ami - `~/ami/sources.hjson`, for example:
```json
    "etho.node": "/path/to/packages/etho.node/src"
    "etho.binaries": "/path/to/packages/ami/etho.binaries/src"
```
*HINT: Do not use path with `~`.*
4. Run ami with `--local-sources` (It is recommended to use `trace` log level for testing)
    * `ami --local-source=~/ami/sources.hjson -ll=trace <command>` 

### Notes

`ami` packages local source as zip and copies it into cache to provide closest experience to using AIR repository. This will pollute your cache and you should clean it from time to time - it wont cause any issue, but it will take some space.

### Single package extension testing

You can test single ami extension (.lua) file with `--dry-run` and `--dry-run-config` options.

`--dry-run` makes sure that ami loads all necessary information and ami api but won't continue in execution of app interface. Rather it loads and executes extension with path from first non option argument

`--dry-run-config=<path or h/json string>` specifies configuration which you want to use
- by default ami loads app.h/json. You can suppress this by using above option

Example: `ami --dry-run --dry-run-config="{ type: test }" download-binaries.lua`

// TODO: Plugin