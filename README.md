# Diffconfig

Provides mix tasks to dump and compare application configurations, with
support for setting environment variables.

## Examples

Dump the current configuration:

```
mix diffconfig.dump /path/to/config1.term
```

Read the configuration:

```
mix diffconfig.read /path/to/config1.term
```

Make some changes to your configuration, and then dump it again:

```
mix diffconfig.dump /path/to/config2.term
```

Compare them:

```
mix diffconfig /path/to/config1.term /path/to/config2.term
```

You can also use it to compare the configurations for two different environments:

```
MIX_ENV=dev mix diffconfig.dump dev.config.term
MIX_ENV=prod mix diffconfig.dump prod.config.term

mix diffconfig dev.config.term prod.config.term

[
  {:changed, [:your_app, :value], "some-dev-value", "some-prod-value"},
  # ...
]
```

If you want to see the fully evaluated configuration, you can dump it and immediately read it back:

```
mix diffconfig.dump | xargs mix diffconfig.read
```

Use the following for more information about each command:

```
mix help diffconfig
mix help diffconfig.dump
mix help diffconfig.read
```

## Installation

```elixir
def deps do
  [
    {:diffconfig, "~> 0.1.0"}
  ]
end
```

## License

See `LICENSE`.
