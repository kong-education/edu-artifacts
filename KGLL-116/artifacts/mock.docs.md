# Overview
## HTTP Methods
**Unless otherwise indicated**: all Endpoints will accept any HTTP request with any header, using any of the supported HTTP Methods: DELETE, GET, HEAD, POST, PUT, OPTIONS, TRACE, COPY, LOCK, MKCOL, MOVE, PROPFIND, PROPPATCH, SEARCH, UNLOCK, REPORT, MKACTIVITY, CHECKOUT, MERGE, M-SEARCH, NOTIFY, SUBSCRIBE, UNSUBSCRIBE, PATCH, PURGE
```
# GET
curl HOST/request

# PATCH
curl -X PATCH HOST/request

# SEARCH /request
curl -X SEARCH HOST/request
```
You can use the X-HTTP-Method-Override header to mock a custom HTTP Method by sending a POST request with the desired HTTP method:
```
# SEARCH /request
curl -X POST -H "X-HTTP-Method-Override: HELLO" HOST/request
```

## Content Negotiation
mockbin is able to respond in a number of formats: JSON, YAML, XML, HTML. The response varies based on Accept header:
```
# Response in JSON (default)
curl HOST/request -H "Accept: application/json" 

# Response in YAML
curl HOST/request -H "Accept: application/yaml" 

# Response in XML
curl HOST/request -H "Accept: application/xml" 

# Response in HTML 
curl HOST/request -H "Accept: text/html" 
```

## JSONP Callbacks
You can receive a JSONP response by adding the query string __callback:
```
curl HOST/request?__callback=myfunc -H "Accept: application/json"
```

## API Endpoints
**/agent**

Returns user-agent.

**/echo**

Returns a response with identical Body and Content-Type to what's in the request.

**/headers**

Returns the values of the request headers.

**/ip**

Returns Origin IP.

**/request**

Returns request details.


