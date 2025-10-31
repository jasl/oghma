# Oghma

Oghma is a self-hosted AI-driven NAS software, which is designed for Pro-users for assets management and knowledge base.

UNDER CONSTRUCTION...

## Requirements

- Ruby 3.4.7+
- PostgreSQL

## Prepare

- Install essential dependencies
- `git clone`
- `bin/setup`
- Edit `config/settings.local.yml`

## Upgrade

- `git pull`
- `bundle`
- `rails db:migrate`

## Run

Start Rails server with embedded background job scheduler: `SOLID_QUEUE_IN_PUMA=1 rails s`

## API

TODO

## License

This repository is licensed under the [Apache License 2.0](LICENSE).
