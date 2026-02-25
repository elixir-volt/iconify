defmodule Iconify.Svg do
  @moduledoc """
  SVG rendering utilities for Iconify icons.
  """

  alias Iconify.Icon

  @doc """
  Renders an icon as an SVG string.

  ## Options

    * `:class` - CSS class(es) to add
    * `:id` - Element ID
    * `:fill` - Fill color (default: "currentColor")
    * `:stroke` - Stroke color
    * `:width` - Override width
    * `:height` - Override height
    * Any other options are added as attributes

  """
  @spec render(Icon.t(), keyword()) :: String.t()
  def render(%Icon{} = icon, opts \\ []) do
    {fill, opts} = Keyword.pop(opts, :fill, "currentColor")
    attrs = build_attrs(icon, opts, fill)

    [
      "<svg",
      ~s( xmlns="http://www.w3.org/2000/svg"),
      ~s( viewBox="#{Icon.viewbox(icon)}"),
      ~s( fill="#{fill}"),
      ~s( aria-hidden="true"),
      attrs,
      ">",
      icon.body,
      "</svg>"
    ]
    |> IO.iodata_to_binary()
  end

  defp build_attrs(_icon, opts, _fill) do
    opts
    |> Enum.map(fn {key, value} ->
      key_str = key |> to_string() |> String.replace("_", "-")
      ~s( #{key_str}="#{escape_attr(value)}")
    end)
  end

  defp escape_attr(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_attr(value), do: escape_attr(to_string(value))
end
