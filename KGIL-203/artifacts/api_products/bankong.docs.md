# Overview

## HTTP Methods

**Unless otherwise indicated**: all Endpoints will accept any HTTP request with any header, using any of the supported HTTP Methods: DELETE, GET, HEAD, POST, and PUT.


<!-- $ http $CPURL/core-entities/routes  --auth-type=bearer --auth=$MYPAT  | jq '.data[] | "\(.name) \(.paths[])"' -->

# Routes

The following routes are available

Transactions_API_of_BanKonG-cancelTransaction - `~/transactions/(?<id>[^/]+)$"`

Transactions_API_of_BanKonG-listTranactions - `~/transactions$"`

Transactions_API_of_BanKonG-changeTransaction - `~/transactions/(?<id>[^/]+)$"`

Transactions_API_of_BanKonG-getTransaction - `~/transactions/(?<id>[^/]+)$"`

Transactions_API_of_BanKonG-initiate_a_transaction - `~/transactions$"`

## Examples

```
# GET all transactions
$ curl HOST/transactions

# GET specific transaction
curl HOST/transactions/<id>

# PATCH
curl -X PATCH HOST/request

# SEARCH /request
curl -X SEARCH HOST/request
```
. . .
