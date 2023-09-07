## Dump Postgres settings as JSON reference

### Install dependencies

Debian / Ubuntu 22 dependencies:
```shell
sudo apt update
sudo apt install ruby-dev
```
```shell
sudo gem install bundler
```

Ruby dependencies:
```shell
bundle config set --local path './vendor'
bundle install
```


### Usage

NB: you have to be logged in as superuser to see all available settings.

```shell
bundle exec ruby ./get_pg_settings.rb \
    --path './postgres_settings_v16.gen.json' \
    --database-url 'postgres://@/postgres'
```
