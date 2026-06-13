# White House — a democratic priorities platform

A modern **Ruby on Rails 8** rebuild of the open-source [White House 2](http://whitehouse2.org/)
project: a place where thousands of people decide together what the government
should do. People add **priorities**, **endorse** or **oppose** them, **rank**
their own list, argue with **points** and **documents**, and watch the combined
rankings produce a live leaderboard.

The original was written for Rails 2.3 (2009) and no longer runs on modern
Ruby. This is a clean rewrite on Ruby 3.3 / Rails 8 that boots, is fully
functional, tested, and deployable. The original code is preserved under
[`legacy/`](legacy/) for reference.

## What's implemented

- **Accounts & auth** — sign up, sign in/out, sessions, password reset
  (Rails 8 built-in authentication), public profiles, settings.
- **Priorities** — create, browse leaderboards (top / rising / falling /
  controversial / newest / finished / yours), tag by issue, propose changes.
- **Endorsements** — endorse (up) or oppose (down); drag-to-rank your personal
  list; weighted scoring where higher-ranked picks carry more weight, combined
  into the global leaderboard position.
- **Points** — short pro/con arguments with helpful / not-helpful ratings.
- **Documents** — long-form collaborative essays for and against a priority.
- **Issues (tags)** — browse priorities by category.
- **Activity feed & comments** — a site-wide feed of events, each commentable.
- **People** — follow users, send private messages, notifications.
- **Branches** — sub-communities with their own ranked priorities.
- **Official status** — a designated "leader" account whose endorsements mark a
  priority as officially endorsed, plus finished/successful/compromised states.
- **Admin** — dashboard, manage priorities/users/pages/blurbs and site settings.

## Tech

- Ruby 3.3, Rails 8.1, SQLite (with Solid Queue / Cache / Cable).
- Hotwire (Turbo + Stimulus), Propshaft assets, import maps — no Node build step.
- Plain, dependency-light server-rendered UI.

## Running locally

```bash
bin/setup            # installs gems, prepares the DB, seeds demo data
bin/rails server     # http://localhost:3000
```

Or manually:

```bash
bundle install
bin/rails db:prepare # create, migrate, seed
bin/rails server
```

### Demo logins (seeded)

All seeded accounts use the password **`password123`**:

| Email                   | Role              |
|-------------------------|-------------------|
| `president@example.gov` | official + admin  |
| `admin@example.com`     | admin             |
| `jordan@example.com`    | member            |

## Tests

```bash
bin/rails test
```

Covers the core domain (endorsement scoring, flipping, leaderboard ranking,
tagging) and key flows (signup, login-gated endorsing, admin protection).

## Deploying

The app ships with a [`railpack.toml`](railpack.toml) for one-command deploys.
Set a `SECRET_KEY_BASE` environment variable (`bin/rails secret`) and mount a
persistent volume at `./storage` for the SQLite databases. A `Dockerfile` and
Kamal config are also included for container/Kamal deploys.

## License

MIT, same as the original White House 2 and Ruby on Rails.
