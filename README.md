# Iconify

Elixir library for working with [Iconify](https://iconify.design) icons.

Access 200,000+ icons from 150+ icon sets. Browse available icons at [icon-sets.iconify.design](https://icon-sets.iconify.design).

## Installation

Add `iconify` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:iconify, "~> 0.1.0"},
    {:req, "~> 0.5"}  # Optional, for fetching icons
  ]
end
```

## Usage

### Loading Icon Sets

```elixir
# From a local file
{:ok, set} = Iconify.Set.load("path/to/heroicons.json")

# From a JSON string
{:ok, set} = Iconify.Set.parse(json_string)
```

### Getting Icons

```elixir
# Get an icon from a set
{:ok, icon} = Iconify.Set.get(set, "user")

# Or raise if not found
icon = Iconify.Set.get!(set, "user")
```

### Rendering SVG

```elixir
# Basic rendering
svg = Iconify.to_svg(icon)
# => "<svg xmlns=\"...\" viewBox=\"0 0 24 24\">...</svg>"

# With attributes
svg = Iconify.to_svg(icon, class: "w-6 h-6", id: "user-icon")
```

### Fetching from Iconify

If you have `req` installed, you can fetch icons directly:

```elixir
# Fetch entire icon set from NPM
{:ok, set} = Iconify.Fetcher.fetch_set("heroicons")

# Fetch specific icons from Iconify API
{:ok, icons} = Iconify.Fetcher.fetch_icons("heroicons", ["user", "home"])

# Fetch single icon
{:ok, icon} = Iconify.Fetcher.fetch_icon("heroicons", "user")
```

## Phoenix Integration

For Phoenix LiveView integration with compile-time icon discovery, see [phoenix_iconify](https://hex.pm/packages/phoenix_iconify).

## IconifyJSON Format

This library works with the standard [IconifyJSON format](https://iconify.design/docs/types/iconify-json.html):

```json
{
  "prefix": "heroicons",
  "width": 24,
  "height": 24,
  "icons": {
    "user": {
      "body": "<path fill=\"currentColor\" d=\"...\"/>"
    }
  }
}
```

Icon sets are available from:
- NPM packages: `@iconify-json/{prefix}` (e.g., `@iconify-json/heroicons`)
- Iconify API: `api.iconify.design`

## License

MIT
