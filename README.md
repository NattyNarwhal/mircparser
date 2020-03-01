# MircParser

Parses mIRC formatting into HTML strings or a list of tokens. It handles
properly closing tags and generates structurally valid HTML.

## Ideas

* Support hex colours (`04`).
* Fully convert tags over to semantic CSS style based versions.
* Allow different kinds of tags; pass a module implementing protocol?
* Sanitize HTML for you instead of assuming it's already so

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mircparser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mircparser, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mircparser](https://hexdocs.pm/mircparser).

