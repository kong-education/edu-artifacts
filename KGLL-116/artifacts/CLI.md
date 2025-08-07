```shell
source ~/initlab.sh
```
## Create a Konnect account


## Configure a Runtime


## Proxy & Test a Service
```shell
http --headers http://$KONNECT_GATEWAY/mock
```

## Productize an API


## Add Specs & Documentation
```shell
cat mock.dock.md
$ cat mock.OAS.yaml
```

## Register an Application
```shell
http GET http://$KONNECT_GATEWAY/mock/echo apikey:SLXnhEpFU5hiWwlJiFxMtKRQnyKytyj3
```

