Since `0.18.0` ami supports loading configuration based on environment. Environment is always merged with default configuration file if available.

Assuming following files exists:
```hjson
// app.json
id: test
type: test.app
configuration: {
   APP_KEY: "<PROD_API_KEY>"
}
```
```hjson
// app.dev.json
configuration: {
   APP_KEY: "<DEV_API_KEY>"
}
```
and executing:
```sh
ami --environment=dev ...
```
The resulting config ami loads will be:
```hjson
id: test
type: test.app
configuration: {
   APP_KEY: "<DEV_API_KEY>"
}
```