# Iconify for Elixir - Implementation Plan

## Overview

Two separate hex packages:

- **`iconify`** - Core Elixir library for working with Iconify icons (no Phoenix dependency)
- **`phoenix_iconify`** - Phoenix LiveView components and compile-time icon discovery

## How Iconify Publishes Icons

Iconify provides icons in multiple formats:

1. **`@iconify-json/{prefix}`** - Individual NPM packages per icon set (recommended)
2. **`@iconify/json`** - One giant NPM package with all icons (~100MB)
3. **Iconify API** - HTTP API at `api.iconify.design` for on-demand fetching

**IconifyJSON format:**
```json
{
  "prefix": "heroicons",
  "width": 24,
  "height": 24,
  "icons": {
    "user": {
      "body": "<path fill=\"currentColor\" d=\"...\"/>"
    }
  },
  "aliases": {
    "person": { "parent": "user" }
  }
}
```

## Package 1: `iconify`

Pure Elixir library. No Phoenix dependency.

### Dependencies
- `jason` - JSON parsing
- `req` - HTTP client (optional, for fetching)

### Public API

```elixir
# Parse icon set from JSON
{:ok, set} = Iconify.Set.load("path/to/heroicons.json")
{:ok, set} = Iconify.Set.parse(json_string)

# Get icon data
{:ok, icon} = Iconify.Set.get(set, "user")
# => %Iconify.Icon{name: "user", body: "<path.../>", width: 24, height: 24}

# Build SVG string
svg = Iconify.to_svg(icon)
svg = Iconify.to_svg(icon, class: "w-6 h-6")
# => "<svg xmlns=\"...\" class=\"w-6 h-6\" viewBox=\"0 0 24 24\">...</svg>"

# Fetch icon set from NPM
{:ok, set} = Iconify.Fetcher.fetch_set("heroicons")

# Fetch individual icons from API
{:ok, icons} = Iconify.Fetcher.fetch_icons("heroicons", ["user", "home"])
```

### Data Structures

```elixir
defmodule Iconify.Icon do
  defstruct [
    :name,
    :body,        # SVG content (without <svg> wrapper)
    width: 24,
    height: 24,
    left: 0,
    top: 0
  ]
end

defmodule Iconify.Set do
  defstruct [
    :prefix,
    :icons,       # %{name => %Icon{}}
    :aliases,     # %{alias => parent_name}
    width: 24,
    height: 24
  ]
end
```

### File Structure

```
iconify/
├── lib/
│   ├── iconify.ex
│   └── iconify/
│       ├── icon.ex
│       ├── set.ex
│       ├── fetcher.ex
│       └── svg.ex
├── mix.exs
└── test/
```

## Package 2: `phoenix_iconify`

Phoenix LiveView integration with compile-time icon discovery.

### Dependencies
- `iconify` - Core library
- `phoenix_live_view` - Phoenix components

### User Experience

```elixir
# 1. Add to mix.exs
{:phoenix_iconify, "~> 1.0"}

# 2. Add compiler to mix.exs
def project do
  [
    compilers: Mix.compilers() ++ [:phoenix_iconify],
    ...
  ]
end

# 3. Import in your components
import PhoenixIconify

# 4. Use in templates
<.icon name="heroicons:user" class="w-5 h-5" />
<.icon name="lucide:home" />
<.icon name={@dynamic_icon} />  # Dynamic also works
```

### How It Works

#### Compile-Time Discovery

Phoenix's HEEx compiler tracks all component calls via `__components_calls__` module attribute. Our Mix compiler:

1. Runs after Elixir compilation
2. Iterates all modules with `__components_calls__/0`
3. Filters calls to our `icon` component
4. Extracts literal `name` attribute values
5. Fetches missing icons from Iconify
6. Updates manifest in `priv/`
7. Triggers recompilation to embed new icons

#### Data Storage

```
priv/
  iconify/
    cache/
      heroicons.json    # Cached IconifyJSON
      lucide.json
    manifest.etf        # Compiled icon data
```

#### The Component

```elixir
defmodule PhoenixIconify do
  use Phoenix.Component

  # Embed icons at compile time
  @manifest_path Application.app_dir(:my_app, "priv/iconify/manifest.etf")
  
  @icons if File.exists?(@manifest_path) do
    @external_resource @manifest_path
    File.read!(@manifest_path) |> :erlang.binary_to_term()
  else
    %{}
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
    icon_data = Map.get(@icons, assigns.name) || fallback()
    assigns = assign(assigns, :body, icon_data.body)
    assigns = assign(assigns, :viewbox, "0 0 #{icon_data.width} #{icon_data.height}")

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox={@viewbox} fill="currentColor" 
         class={@class} aria-hidden="true" {@rest}>
      <%= Phoenix.HTML.raw(@body) %>
    </svg>
    """
  end
  
  defp fallback do
    %{body: ~S|<path d="..."/>|, width: 24, height: 24}
  end
end
```

### Mix Compiler

```elixir
defmodule Mix.Tasks.Compile.PhoenixIconify do
  use Mix.Task.Compiler

  @recursive true

  def run(_args) do
    # 1. Collect icons from __components_calls__
    icons = PhoenixIconify.Collector.collect()
    
    # 2. Load existing manifest
    manifest = PhoenixIconify.Manifest.read()
    
    # 3. Find missing icons
    missing = Enum.reject(icons, &Map.has_key?(manifest, &1))
    
    # 4. Fetch missing from Iconify
    fetched = PhoenixIconify.Fetcher.fetch(missing)
    
    # 5. Update manifest
    updated = Map.merge(manifest, fetched)
    PhoenixIconify.Manifest.write(updated)
    
    # 6. Report
    if missing != [] do
      Mix.shell().info("PhoenixIconify: Fetched #{length(missing)} new icons")
    end
    
    {:ok, []}
  end
end
```

### Collector

```elixir
defmodule PhoenixIconify.Collector do
  def collect do
    for module <- get_compiled_modules(),
        function_exported?(module, :__components_calls__, 0),
        call <- module.__components_calls__(),
        icon_name <- extract_icon_name(call),
        uniq: true do
      icon_name
    end
  end

  defp extract_icon_name(%{component: component, props: props}) do
    # Check if this is our icon component
    if icon_component?(component) do
      case find_name_prop(props) do
        {:ok, name} when is_binary(name) -> [name]
        _ -> []
      end
    else
      []
    end
  end
  
  defp icon_component?({PhoenixIconify, :icon}), do: true
  defp icon_component?({_, :icon}), do: true  # User's wrapper
  defp icon_component?(_), do: false
  
  defp find_name_prop(props) do
    Enum.find_value(props, :error, fn
      %{name: :name, value: value} -> {:ok, extract_value(value)}
      _ -> nil
    end)
  end
  
  defp extract_value({:string, value, _}), do: value
  defp extract_value(value) when is_binary(value), do: value
  defp extract_value(_), do: nil
end
```

### Configuration

```elixir
# config/config.exs
config :phoenix_iconify,
  fallback: "heroicons:question-mark-circle",
  cache_path: "priv/iconify"  # Optional, this is default
```

### File Structure

```
phoenix_iconify/
├── lib/
│   ├── phoenix_iconify.ex
│   ├── phoenix_iconify/
│   │   ├── collector.ex
│   │   ├── manifest.ex
│   │   └── fetcher.ex
│   └── mix/
│       └── tasks/
│           └── compile/
│               └── phoenix_iconify.ex
├── priv/
│   └── iconify/
│       └── .gitkeep
├── mix.exs
└── test/
```

## Open Issues from Original Library

| Issue | Resolution |
|-------|------------|
| #24 CI setup unclear | Fixed - Icons discovered and cached automatically |
| #20 LiveView 1.0 | Fixed - Proper deps |
| #19 README update | Fixed - Simplified config |
| #18 CHANGELOG | Will add |
| #16 Release issues | Fixed - Icons embedded at compile time via `@external_resource` |
| #6 Umbrella paths | Fixed - No path config needed, uses standard `priv/` |

## Benefits

1. **No runtime npm/yarn** - Icons fetched once at compile time
2. **No JSON files in production** - Everything compiled into BEAM
3. **Compile-time validation** - Typos caught during compilation
4. **Optimal LiveView diffing** - Only attributes change, SVG content is static
5. **User chooses icon sets** - Only used icons are bundled
6. **Works in releases** - No file system access needed
7. **Standard patterns** - Uses `priv/`, `@external_resource`, Mix compiler

## Implementation Status

### `iconify` core library ✅
- [x] Icon struct (`Iconify.Icon`)
- [x] Set parsing (`Iconify.Set`)
- [x] SVG generation (`Iconify.Svg`)
- [x] Fetcher - NPM + API (`Iconify.Fetcher`)
- [x] Tests (33 passing)

### `phoenix_iconify` ✅
- [x] Basic component (`<.icon name="heroicons:user" />`)
- [x] Scanner (extracts icons from HEEx source files)
- [x] Manifest management (priv/iconify/manifest.etf)
- [x] Mix compiler (`mix compile.phoenix_iconify`)
- [x] Phoenix `hero-` prefix compatibility
- [x] Compile-time warnings for unknown icons
- [x] Tests (7 passing)

### Example App ✅
- [x] Created iconify_example Phoenix app
- [x] Integrated phoenix_iconify
- [x] Tested with multiple icon sets (heroicons, lucide, mdi)
- [x] Verified rendering works correctly
