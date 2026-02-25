defmodule Iconify.Icon do
  @moduledoc """
  Represents a single icon from an Iconify icon set.

  ## Fields

    * `:name` - Icon name (e.g., "user", "home")
    * `:body` - SVG content without the `<svg>` wrapper
    * `:width` - Icon width (default: 24)
    * `:height` - Icon height (default: 24)
    * `:left` - Left position of viewBox (default: 0)
    * `:top` - Top position of viewBox (default: 0)

  """

  @type t :: %__MODULE__{
          name: String.t(),
          body: String.t(),
          width: pos_integer(),
          height: pos_integer(),
          left: integer(),
          top: integer()
        }

  @enforce_keys [:name, :body]
  defstruct [
    :name,
    :body,
    width: 24,
    height: 24,
    left: 0,
    top: 0
  ]

  @doc """
  Creates an Icon struct from a map (typically parsed from IconifyJSON).

  ## Examples

      iex> Iconify.Icon.new("user", %{"body" => "<path/>", "width" => 24, "height" => 24})
      %Iconify.Icon{name: "user", body: "<path/>", width: 24, height: 24, left: 0, top: 0}

  """
  @spec new(String.t(), map(), keyword()) :: t()
  def new(name, data, defaults \\ []) when is_binary(name) and is_map(data) do
    %__MODULE__{
      name: name,
      body: Map.fetch!(data, "body"),
      width: data["width"] || defaults[:width] || 24,
      height: data["height"] || defaults[:height] || 24,
      left: data["left"] || defaults[:left] || 0,
      top: data["top"] || defaults[:top] || 0
    }
  end

  @doc """
  Returns the viewBox string for this icon.

  ## Examples

      iex> icon = %Iconify.Icon{name: "test", body: "", width: 24, height: 24, left: 0, top: 0}
      iex> Iconify.Icon.viewbox(icon)
      "0 0 24 24"

  """
  @spec viewbox(t()) :: String.t()
  def viewbox(%__MODULE__{left: left, top: top, width: width, height: height}) do
    "#{left} #{top} #{width} #{height}"
  end
end
