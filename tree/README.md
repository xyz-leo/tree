# Tree

Self-hosted link tree page built with Rails. Content is edited in a small admin panel at `/admin`
(sign in at `/sessions/new`); the single admin user is created from `ADMIN_EMAIL` and `ADMIN_PASSWORD`
by `bin/rails db:seed`.

## Development

```sh
cd tree
bin/setup      # installs gems and starts the dev server on :3000
bin/ci         # lint, security scans, tests
```

## Deployment

Runs as a Docker container behind Caddy on a shared Docker network. From the repo root:

```sh
cp docker/.env.example docker/.env   # set RAILS_MASTER_KEY, APP_HOSTS, ADMIN_EMAIL, ADMIN_PASSWORD
docker compose -f docker/compose.yml up -d --build
```

Caddyfile:

```
links.example.com {
    reverse_proxy tree:80
}
```
