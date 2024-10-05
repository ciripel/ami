## AMI - Application Management Interface

### Setup

`wget -q https://raw.githubusercontent.com/alis-is/ami/master/install.sh -O /tmp/install.sh && sudo sh /tmp/install.sh`

### Usage

1. Create directory for your application (it should not be part of user home folder structure, you can use for example `/apps/myapp`)
2. Create `app.json` or `app.hjson` with app configuration you like, e.g.:
```json
{
    "id": "etho1",
    "type": {
        "id": "etho.node"
    },
    "configuration": {
        "NODE_TYPE" : "masternode",
    },
    "user": "test"
}
```

3. Run `ami --path=<your app path> setup --app`
   * e.g. `ami --path=/apps/myapp`
4. Run `ami --path=<your app path> --help` to investigate available commands
5. Proceed based on your app documentation