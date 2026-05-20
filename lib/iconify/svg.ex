defmodule Iconify.SVG do
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
    * `:rotate` - Additional 90-degree rotations
    * `:h_flip` - Apply horizontal flip
    * `:v_flip` - Apply vertical flip
    * Any other options are added as attributes

  """
  @spec render(Icon.t(), keyword()) :: String.t()
  def render(%Icon{} = icon, opts \\ []) do
    {fill, opts} = Keyword.pop(opts, :fill, "currentColor")
    {body, viewbox} = build_body(icon, opts)
    attrs = build_attrs(opts)

    [
      "<svg",
      ~s( xmlns="http://www.w3.org/2000/svg"),
      ~s( viewBox="#{viewbox}"),
      ~s( fill="#{escape_attr(fill)}"),
      ~s( aria-hidden="true"),
      attrs,
      ">",
      body,
      "</svg>"
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  Returns transformed icon body and viewBox without wrapping it in an SVG element.
  """
  @spec build_body(Icon.t(), keyword()) :: {String.t(), String.t()}
  def build_body(%Icon{} = icon, opts \\ []) do
    rotate = Integer.mod(icon.rotate + Keyword.get(opts, :rotate, 0), 4)
    h_flip = icon.h_flip != Keyword.get(opts, :h_flip, false)
    v_flip = icon.v_flip != Keyword.get(opts, :v_flip, false)

    transform_icon(%{icon | rotate: rotate, h_flip: h_flip, v_flip: v_flip})
  end

  defp transform_icon(%Icon{} = icon) do
    box = %{left: icon.left, top: icon.top, width: icon.width, height: icon.height}
    {body, box} = apply_transformations(icon.body, box, icon.h_flip, icon.v_flip, icon.rotate)
    {body, "#{box.left} #{box.top} #{box.width} #{box.height}"}
  end

  defp apply_transformations(body, box, h_flip, v_flip, rotate) do
    {transforms, box, rotate} = flip_transforms(box, h_flip, v_flip, rotate)
    {transforms, box} = rotate_transforms(transforms, box, Integer.mod(rotate, 4))
    body = if transforms == [], do: body, else: wrap(body, transforms)
    {body, box}
  end

  defp flip_transforms(box, true, true, rotate), do: {[], box, rotate + 2}

  defp flip_transforms(box, true, false, rotate) do
    transforms = ["translate(#{box.width + box.left} #{0 - box.top})", "scale(-1 1)"]
    {transforms, %{box | left: 0, top: 0}, rotate}
  end

  defp flip_transforms(box, false, true, rotate) do
    transforms = ["translate(#{0 - box.left} #{box.height + box.top})", "scale(1 -1)"]
    {transforms, %{box | left: 0, top: 0}, rotate}
  end

  defp flip_transforms(box, false, false, rotate), do: {[], box, rotate}

  defp rotate_transforms(transforms, box, 0), do: {transforms, box}

  defp rotate_transforms(transforms, box, 1) do
    value = box.height / 2 + box.top
    {["rotate(90 #{format_number(value)} #{format_number(value)})" | transforms], swap_box(box)}
  end

  defp rotate_transforms(transforms, box, 2) do
    x = box.width / 2 + box.left
    y = box.height / 2 + box.top
    {["rotate(180 #{format_number(x)} #{format_number(y)})" | transforms], box}
  end

  defp rotate_transforms(transforms, box, 3) do
    value = box.width / 2 + box.left
    {["rotate(-90 #{format_number(value)} #{format_number(value)})" | transforms], swap_box(box)}
  end

  defp swap_box(box) do
    %{box | left: box.top, top: box.left, width: box.height, height: box.width}
  end

  defp wrap(body, transforms) do
    ~s(<g transform="#{Enum.join(transforms, " ")}">#{body}</g>)
  end

  defp build_attrs(opts) do
    opts
    |> Keyword.drop([:rotate, :h_flip, :v_flip])
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

  defp format_number(value) when is_float(value) do
    if value == trunc(value), do: Integer.to_string(trunc(value)), else: Float.to_string(value)
  end

  defp format_number(value), do: to_string(value)
end
