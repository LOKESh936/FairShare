# API Testing App

Tiny local app to test APIs with a browser UI and a built-in proxy.

## Run

```bash
cd /Users/loki/Desktop/FairShare/api-testing
npm start
```

Then open:

- http://127.0.0.1:4173

## Features

- Choose HTTP method + URL
- Set request headers as JSON
- Send raw request body
- Configure timeout
- View response status, headers, body, and duration
- Reuse recent requests from local history

## Notes

- The local `/proxy` endpoint forwards requests server-side to help avoid browser CORS limits.
- For `GET` and `HEAD`, request body is ignored.
