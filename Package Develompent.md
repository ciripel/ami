# Local Testing

You can easily test ami packages locally without need to publish in air repository.
This can be done through switch `--local-sources=<path to sources file>`

Local sources file is simple hjson or json file in format:
```json
{
    "<package id>": "<path to package source>",
    "<package2 id>": "<path to package2 source>"
}
```

So for example if testing btc.base package (*sources.json*):
```json 
{
    "btc.base": "../packages/btc.base/src",
    "btc.binaries": "../packages/btc.binaries/src"
}
```

Then you just run ami commands as follows (we are assuming that you are in app directory and source.json is in its parent dir): 
```sh
ami --local-sources="../sources.json" setup
```

## Plugins

Plugins are automatically resolved from local sources if there is `<package id>` prefixed with `plugin.`.
E.g. for plugin `platform`:
```json
{
    "plugin.platform": "<path to platform plugin source>"
}
```