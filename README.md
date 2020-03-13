# plibra-grant-docker

This is the Dockerfile for pLIBRA (Phala Network) W3F Grant Milestone 2.

## Build

```bash
sudo docker build -t phala:test .
```

## Start

```bash
sudo docker run -p 8080:8080 phala:test
```

Exported endpoints:

- pRuntime RPC: `http://localhost:8080/tee-api`
- Substrate RPC: `ws://localhost:8080/ws`

