# tree

A small, self-hosted "link in bio" page built with Rails: your name, a short bio and grouped
links, in Portuguese and English, with a light/dark theme. You edit everything from a
password-protected admin panel. There's one admin user, no sign-up and no third-party services.

- Public page at `/` (Portuguese) and `/en` (English)
- Admin panel at `/admin`, sign in at `/sessions/new`
- One command to install: `./setup` asks a few questions and starts it with Docker Compose

## Features

- **Profile and grouped links:** name, handle, bio, and link groups (for example "Social",
  "Projects"), each with its own ordered links and an optional short hint.
- **Two languages without I18n:** every text field has a Portuguese and an English version.
  English is optional and falls back to Portuguese.
- **Site icons from the URL:** links to GitHub, Instagram, X/Twitter, LinkedIn, Facebook,
  YouTube and `mailto:` get their icon automatically; other links get a `›` bullet.
- **Light and dark themes:** dark by default. The choice is saved in the browser and applied
  before the first paint, so there's no flash.
- **Link previews:** Open Graph and Twitter card tags, so a pasted link shows a card with your
  name, bio and icon.
- **Private by default:** the public page sets no cookies and loads nothing from other sites.
  A strict Content Security Policy is on.
- **Accessible:** semantic HTML, visible focus states, screen-reader text for links that open
  in a new tab.

## Stack and decisions

| | Choice | Why |
|---|---|---|
| Framework | Rails 8.1, Ruby 3.4 | Familiar, and a whole app like this fits in a few hundred lines. |
| Frameworks loaded | Active Record, Action Controller, Action View, Active Model | No mailer, jobs, file storage or websockets. Nothing here needs them. |
| Database | SQLite in a Docker volume | One small table per concept, one writer. No database server to run. |
| Auth | Rails' built-in authentication generator, trimmed | One user, created by `./setup`. The password is only ever stored as a bcrypt hash in the database, never in a file. No password reset (it needs email) and no sign-up. |
| Frontend | Server-rendered ERB, plain CSS, 3 small JS modules via importmap | No Node, no bundler, no CSS framework, no JS framework. |
| Languages | Two routes (`/` and `/en`) and `_pt`/`_en` columns | Simpler than Rails I18n for a single page with user-written text. |
| Fonts and icons | Self-hosted `.woff2` files, inline SVG icons | No requests to other sites. |
| Deploy | Docker Compose, set up by `./setup` | The image contains the app; the container prepares its own database and secret. No Kamal: its proxy would compete with Caddy for ports 80/443. |
| Security | Strict CSP with per-request nonces, CSRF on admin forms, `frame-ancestors 'none'`, login rate limit, 12+ character password | Cheap to add, and the page is public. |

## Project layout

```
/                  setup (install script), compose.yml, README, LICENSE, .github/ (CI)
/tree              the Rails app and its Dockerfile
```

Inside `tree/`:

```
app/models/            Profile (single row), LinkGroup, Link, User, Session
app/models/concerns/   Translatable (pt/en text), Positioned (ordering)
app/controllers/       LinksController (public page), SessionsController, admin/*
app/helpers/           LinksHelper: site icons, new-tab links
app/views/icons/       one SVG per icon
app/javascript/        theme.js (theme toggle), confirm.js (delete confirmation)
config/initializers/   content_security_policy.rb
db/seeds.rb            creates or updates the admin user
bin/docker-entrypoint  creates or migrates the database on every start
```

## Install

You need a server with Docker (with Compose v2) and a reverse proxy that handles HTTPS, running in
Docker. The examples use Caddy.

1. Clone the repo:

   ```sh
   git clone https://github.com/xyz-leo/tree.git
   cd tree
   ```

2. Run the setup script:

   ```sh
   ./setup
   ```

   It asks for:

   | Question | Example |
   |---|---|
   | Domain | `links.example.com` |
   | Docker network of your reverse proxy | `caddy` (created if it doesn't exist) |
   | Admin email | `you@example.com` |
   | Admin password | 12+ characters |

   Then it writes the domain and network to `.env`, runs `docker compose up -d --build`, and
   creates your admin user. The password goes straight to the app, which stores only its hash; it
   isn't written to any file.

3. Add the block the script prints to your Caddyfile, then reload Caddy:

   ```
   links.example.com {
       reverse_proxy tree:80
   }
   ```

   Caddy's container must be on the same Docker network you gave the script.

4. Open `https://links.example.com/sessions/new`, sign in, and fill in your profile and links.

That's all. On every start, the container creates or migrates the database and, the first time,
generates its secret key. Your content, admin user and secret key live in the `storage` Docker
volume.

### Without Caddy

Any reverse proxy that handles HTTPS works. The app expects HTTPS, so don't expose it over plain
HTTP. If your proxy runs on the host instead of in Docker, add this to the `tree` service in
`compose.yml` and proxy to `127.0.0.1:8080`:

```yaml
    ports:
      - "127.0.0.1:8080:80"
```

## Development

To work on the code without Docker you need Ruby 3.4 (exact version in `tree/.ruby-version`).

1. Install gems and create the database:

   ```sh
   cd tree
   bin/setup --skip-server
   ```

2. Create a local admin user:

   ```sh
   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='your long password' bin/rails db:seed
   ```

3. Start the server:

   ```sh
   bin/dev
   ```

4. Open <http://localhost:3000/sessions/new> and sign in. The public page is at
   <http://localhost:3000> and <http://localhost:3000/en>.

## Customizing

| To change | Edit |
|---|---|
| Name, bio, groups, links | the admin panel at `/admin` |
| Theme colors | CSS variables at the top of `tree/app/assets/stylesheets/application.css` (`:root` = dark, `[data-theme="light"]` = light) |
| Favicon and link preview image | replace `tree/public/icon.png` and `tree/public/apple-touch-icon.png` |
| Fonts | `tree/app/assets/fonts/` and `tree/app/assets/stylesheets/fonts.css` |

### Adding an icon for another site

1. Add the domain to `ICON_DOMAINS` in `tree/app/helpers/links_helper.rb`:

   ```ruby
   "mastodon.social" => "mastodon",
   ```

2. Create `tree/app/views/icons/_mastodon.html.erb` with a 24×24 SVG that uses
   `stroke="currentColor"` (copy an existing icon as a template).

3. Run `bin/rails test`. It fails if a mapped icon has no SVG file.

### Changing the languages

Portuguese (`/`) and English (`/en`) are set in:

1. `Translatable::LANGS` in `tree/app/models/concerns/translatable.rb`
2. the `_pt`/`_en` columns in `tree/db/migrate/`
3. the two routes at the bottom of `tree/config/routes.rb`
4. `HTML_LANGS` and `OG_LOCALES` in `tree/app/helpers/application_helper.rb`
5. `NEW_TAB_TEXT` in `tree/app/helpers/links_helper.rb`

### Rules for views

The Content Security Policy blocks inline styles and scripts, so in views:

- don't use `style=""` attributes; add a CSS class instead
- don't use `onclick=""` or other `on*` attributes; add a JS module in `tree/app/javascript/`
- give inline `<script>` tags `nonce: true` (`javascript_tag nonce: true do ... end`)

The tests check every page for this.

## Tests and CI

From `tree/`:

| Command | Runs |
|---|---|
| `bin/rails test` | the test suite |
| `bin/ci` | lint, security scans and tests (same as GitHub Actions) |

GitHub Actions runs the security scans, lint and tests on every push and pull request.

The suite covers the models, the public page in both languages, sign in and out (including with
CSRF protection on), every admin action and its access control, the seeds, the icon mapping,
link previews, and the Content Security Policy on every page.

## Metrics

Measured at the time of writing.

| | |
|---|---|
| Application code (`tree/app`) | ~960 lines: models 75, controllers 173, helpers 52, views 313, CSS 324, JS 21 |
| Migrations and seeds | 66 lines |
| Tests | 102 tests, 568 assertions, ~785 lines, about 2.5 s |
| Security and lint | Brakeman: 0 warnings, RuboCop: 0 offenses, bundler-audit and importmap audit: clean |
| Direct gem dependencies | 14 (105 in the lockfile) |
| JavaScript | 3 modules, 21 lines, no libraries |
| Public page weight | ~5 KB gzipped for HTML, CSS and JS, plus ~51 KB of fonts on first visit |
| Cookies on the public page | none |
| Docker image | ~460 MB |

## License

[MIT](LICENSE)
