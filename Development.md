To develop AMI based applications you do not need access to AIR repository nor internet connectivity. 

## Environment Preparation

1. install `ami` and `eli`
    * `wget https://raw.githubusercontent.com/cryon-io/ami/master/install.sh -O /tmp/install.sh && sh /tmp/install.sh`
2. prepare directories for layers you want to develop
    *  Lets say you want to develop/improve `etho.node` and `etho.binaries` layers 
    *  Create directories for your layers e.g.: `mkdir -p ~/ami/etho.binaries ~/ami/etho.node`
3. create source mapping for ami - `~/ami/sources.hjson`, for example:
```json
    "etho.node": "~/ami/etho.node"
    "etho.binaries": "~/ami/etho.binaries"
```
4. Run ami with `--local-sources` (It is recommended to use `trace` log level for testing)
    * `ami --local-source=~/ami/sources.hjson -ll=trace <command>` 

### Notes

`ami` packages local source as zip and copies it into cache to provide closest experience to using AIR repository. This will pollute your cache and you should clean it from time to time - it wont cause any issue, but it will take some space.
