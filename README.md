# Iconify

[![Hex.pm](https://img.shields.io/hexpm/v/iconify.svg)](https://hex.pm/packages/iconify) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/iconify)

Iconify data and SVG rendering for Elixir. Load, fetch, resolve aliases, transform, and render icons from the [Iconify](https://iconify.design) ecosystem without adding JavaScript to your app.

```elixir
{:ok, icon} = Iconify.Fetcher.fetch_icon("lucide", "settings")
Iconify.to_svg(icon, class: "size-5")
```

Iconify gives you access to 200,000+ icons from 150+ icon sets. Browse them at [icon-sets.iconify.design](https://icon-sets.iconify.design).

## Why Iconify

Iconify packages usually target frontend JavaScript. This package gives Elixir code the same icon data model:

- Parses standard IconifyJSON icon sets
- Resolves aliases and alias chains
- Applies Iconify rotations and flips
- Rewrites SVG IDs with Erlang's `:xmerl` to avoid duplicate gradient/mask collisions
- Preserves IconifyJSON metadata such as `info`, `categories`, and `chars`
- Fetches icon sets from `@iconify-json/*` packages
- Fetches individual icons from the Iconify API
- Renders inline SVG strings with safe attribute escaping

It is the core package used by [`phoenix_iconify`](https://hex.pm/packages/phoenix_iconify), but it also works in any Elixir project that needs server-side SVG output.

## Installation

```elixir
def deps do
  [
    {:iconify, "~> 0.2.0"}
  ]
end
```

## Fetch one icon

```elixir
{:ok, icon} = Iconify.Fetcher.fetch_icon("lucide", "settings")

Iconify.to_svg(icon, class: "size-5 text-zinc-700")
```

## Load an icon set

Use local IconifyJSON when you want deterministic builds or offline rendering:

```elixir
{:ok, set} = Iconify.Set.load("priv/iconify/lucide.json")
{:ok, icon} = Iconify.Set.get(set, "settings")

Iconify.to_svg(icon, class: "size-5")
```

You can also parse JSON you already have:

```elixir
{:ok, set} = Iconify.Set.parse(json)
```

## Fetch icon sets

Download complete icon sets from npm packages such as `@iconify-json/lucide`:

```elixir
{:ok, set} = Iconify.Fetcher.fetch_set("lucide")
{:ok, icon} = Iconify.Set.get(set, "settings")
```

Fetch several icons from the Iconify API:

```elixir
{:ok, icons} = Iconify.Fetcher.fetch_icons("lucide", ["settings", "user", "x"])
icons["settings"]
```

## Render SVG

```elixir
Iconify.to_svg(icon,
  class: "size-5",
  id: "settings-icon",
  aria_hidden: "true"
)
```

The renderer forwards extra attributes to `<svg>` and escapes attribute values. By default it follows Iconify's sizing behavior: icons render as `1em` high and preserve their aspect ratio unless you pass `width` or `height`.

```elixir
Iconify.to_svg(icon, height: 24)       # width is calculated from the viewBox
Iconify.to_svg(icon, width: "unset")   # omit the width attribute
Iconify.to_svg(icon, color: "#0f172a") # colors currentColor icons
Iconify.to_svg(icon, inline: true)     # align with text baseline
```

Transformations are supported both from Iconify aliases and render options:

```elixir
Iconify.to_svg(icon, rotate: 1)
Iconify.to_svg(icon, h_flip: true)
Iconify.to_svg(icon, v_flip: true)
```

CSS mask/background rendering is available when you want an Iconify-style CSS icon:

```elixir
Iconify.to_svg(icon, mode: "mask", class: "icon")
Iconify.to_svg(icon, mode: "bg", class: "icon")
```

IDs inside SVG bodies are replaced by default, so rendering the same icon multiple times does not create duplicate `id` collisions for gradients, masks, clip paths, or animations.

## Icon names

Use Iconify's standard `prefix:name` format:

```elixir
Iconify.parse_name("lucide:settings")
# {:ok, "lucide", "settings"}
```

## Phoenix apps

For Phoenix and LiveView, use [`phoenix_iconify`](https://hex.pm/packages/phoenix_iconify):

```heex
<.icon name="lucide:settings" class="size-5" />
```

It discovers icons at compile time, writes a JSON manifest, and renders inline SVGs from the server.

## IconifyJSON

Iconify works with the standard [IconifyJSON format](https://iconify.design/docs/types/iconify-json.html). Renderable icon data is normalized into `%Iconify.Icon{}` structs, while icon set metadata remains available on `%Iconify.Set{}`:

```json
{
  "prefix": "lucide",
  "width": 24,
  "height": 24,
  "icons": {
    "settings": {
      "body": "<path d=\"...\"/>"
    }
  }
}
```

Metadata fields such as `provider`, `info`, `chars`, `categories`, `themes`, `prefixes`, `suffixes`, `last_modified`, and `not_found` are preserved when present.

Icon sets are available from:

- npm packages: `@iconify-json/{prefix}`
- Iconify API: `api.iconify.design`

## Part of Elixir Volt

iconify is the core Iconify data model for Elixir: parse icon sets, resolve aliases, transform, and render SVG.

It is part of a frontend stack that runs inside the BEAM — builds, JS
runtimes, icons, and Vue-to-LiveView compilation as supervised parts of the
application instead of external toolchain processes. See the
[Elixir Volt](https://github.com/elixir-volt) organization for the rest, and
[Building Blocks for the Future Web](https://github.com/elixir-vibe/building-blocks)
for the thesis, architecture, and roadmap that tie them together.

## License

MIT
