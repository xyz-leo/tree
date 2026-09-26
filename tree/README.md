# Tree

Self-hosted link tree page built with Rails. No database, no auth: links live in a YAML file.

## Development

```sh
cd tree
bin/setup      # installs gems and starts the dev server on :3000
bin/ci         # lint, security scans, tests
```

## Deployment

Runs as a Docker container behind Caddy on a shared Docker network. From the repo root:

```sh
cp docker/.env.example docker/.env   # set RAILS_MASTER_KEY and APP_HOSTS
docker compose -f docker/compose.yml up -d --build
```

Caddyfile:

```
links.example.com {
    reverse_proxy tree:80
}
```
