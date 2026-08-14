# MongoConnect API

Simple Netlify Function that accepts JSON via POST and stores it in MongoDB.

## Endpoint

`POST /.netlify/functions/api`

### Headers

```text
x-client-id: <CLIENT_ID>
x-client-secret: <CLIENT_SECRET>
Content-Type: application/json
```
