defmodule Iconify do
  @moduledoc """
  Elixir library for working with Iconify icons.

  Iconify provides access to 200,000+ icons from 150+ icon sets.
  Browse available icons at https://icon-sets.iconify.design

  ## Usage

      # Load an icon set from file
      {:ok, set} = Iconify.Set.load("path/to/heroicons.json")

      # Get an icon
      {:ok, icon} = Iconify.Set.get(set, "user")

      # Render as SVG
      svg = Iconify.to_svg(icon)
      svg = Iconify.to_svg(icon, class: "w-6 h-6")

  ## Fetching Icons

  If you have `req` installed, you can fetch icons from Iconify:

      # Fetch entire icon set from NPM
      {:ok, set} = Iconify.Fetcher.fetch_set("heroicons")

      # Fetch specific icons from Iconify API
      {:ok, icons} = Iconify.Fetcher.fetch_icons("heroicons", ["user", "home"])

  """

  alias Iconify.{Icon, SVG}

  @doc """
  Renders an icon as an SVG string.

  ## Options

    * `:class` - CSS class(es) to add to the SVG element
    * `:width` - Override width (default: icon's width)
    * `:height` - Override height (default: icon's height)
    * Any other options are added as attributes to the SVG element

  ## Examples

      iex> icon = %Iconify.Icon{name: "user", body: "<path d=\\"M10 10\\"/>", width: 24, height: 24}
      iex> Iconify.to_svg(icon)
      ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" height="1em" width="1em"><path d="M10 10"/></svg>)

      iex> icon = %Iconify.Icon{name: "user", body: "<path d=\\"M10 10\\"/>", width: 24, height: 24}
      iex> Iconify.to_svg(icon, class: "w-6 h-6")
      ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" height="1em" width="1em" class="w-6 h-6"><path d="M10 10"/></svg>)

  """
  @spec to_svg(Icon.t(), keyword()) :: String.t()
  def to_svg(%Icon{} = icon, opts \\ []) do
    SVG.render(icon, opts)
  end

  @doc """
  Parses an icon name into prefix and name parts.

  ## Examples

      iex> Iconify.parse_name("heroicons:user")
      {:ok, "heroicons", "user"}

      iex> Iconify.parse_name("mdi:home")
      {:ok, "mdi", "home"}

      iex> Iconify.parse_name("invalid")
      :error

  """
  @spec parse_name(String.t()) :: {:ok, String.t(), String.t()} | :error
  def parse_name(name) when is_binary(name) do
    case String.split(name, ":", parts: 2) do
      [prefix, icon_name] when prefix != "" and icon_name != "" ->
        {:ok, prefix, icon_name}

      _ ->
        :error
    end
  end
end
