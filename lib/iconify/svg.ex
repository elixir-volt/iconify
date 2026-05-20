defmodule Iconify.SVG do
  @moduledoc """
  SVG rendering utilities for Iconify icons.
  """

  alias Iconify.Icon

  @unset_keywords ["unset", "undefined", "none"]
  @attr_names %{
    aria_hidden: :"aria-hidden",
    aria_label: :"aria-label",
    data_testid: :"data-testid",
    phx_click: :"phx-click",
    phx_value: :"phx-value",
    phx_target: :"phx-target"
  }

  @doc """
  Renders an icon as an SVG string.

  ## Options

    * `:class` - CSS class(es) to add
    * `:id` - Element ID
    * `:fill` - Fill color (default: "currentColor")
    * `:stroke` - Stroke color
    * `:color` - Text color used by `currentColor` icons
    * `:width` - Override width. Defaults to `"1em"` and preserves aspect ratio
    * `:height` - Override height. Defaults to `"1em"` and preserves aspect ratio
    * `:inline` - Align icon with text baseline
    * `:mode` - `"svg"`, `"mask"`, or `"bg"` rendering mode
    * `:rotate` - Additional 90-degree rotations
    * `:h_flip` - Apply horizontal flip
    * `:v_flip` - Apply vertical flip
    * `:replace_ids` - Replace SVG IDs to avoid page-level collisions. Enabled by default
    * `:id_prefix` - Prefix to use when replacing IDs
    * Any other options are added as attributes

  """
  @spec render(Icon.t(), keyword()) :: String.t()
  def render(%Icon{} = icon, opts \\ []) do
    {mode, opts} = Keyword.pop(opts, :mode, "svg")

    case to_string(mode) do
      "mask" -> render_span(icon, opts, :mask)
      "bg" -> render_span(icon, opts, :bg)
      _ -> render_svg(icon, opts)
    end
  end

  @doc """
  Returns transformed icon body and viewBox without wrapping it in an SVG element.
  """
  @spec build_body(Icon.t(), keyword()) :: {String.t(), String.t()}
  def build_body(%Icon{} = icon, opts \\ []) do
    data = build_data(icon, opts)
    {data.body, data.viewbox}
  end

  @doc """
  Returns transformed icon data used for rendering.
  """
  @spec build_data(Icon.t(), keyword()) :: %{
          body: String.t(),
          viewbox: String.t(),
          width: String.t() | number(),
          height: String.t() | number()
        }
  def build_data(%Icon{} = icon, opts \\ []) do
    rotate = Integer.mod(icon.rotate + Keyword.get(opts, :rotate, 0), 4)
    h_flip = icon.h_flip != Keyword.get(opts, :h_flip, false)
    v_flip = icon.v_flip != Keyword.get(opts, :v_flip, false)

    {body, box} = transform_icon(%{icon | rotate: rotate, h_flip: h_flip, v_flip: v_flip})
    {width, height} = dimensions(box, opts)

    %{
      body: replace_ids(body, opts),
      viewbox: viewbox(box),
      width: width,
      height: height
    }
  end

  @doc """
  Replaces IDs in SVG content to avoid collisions when rendering the same icon more than once.
  """
  @spec replace_ids(String.t(), keyword()) :: String.t()
  def replace_ids(body, opts \\ []) when is_binary(body) do
    if Keyword.get(opts, :replace_ids, true) do
      replace_parsed_ids(body, Keyword.get_lazy(opts, :id_prefix, &unique_id_prefix/0))
    else
      body
    end
  end

  defp render_svg(icon, opts) do
    {fill, opts} = Keyword.pop(opts, :fill, "currentColor")
    {color, opts} = Keyword.pop(opts, :color, nil)
    {inline, opts} = Keyword.pop(opts, :inline, false)
    data = build_data(icon, opts)

    attrs =
      opts
      |> put_default_attr(:width, data.width)
      |> put_default_attr(:height, data.height)
      |> put_style(color: color, inline: inline)
      |> svg_attrs(data, fill)

    data.body
    |> parse_fragment!()
    |> then(&{:svg, attrs, &1})
    |> render_element()
  end

  defp render_span(icon, opts, mode) do
    {color, opts} = Keyword.pop(opts, :color, nil)
    {inline, opts} = Keyword.pop(opts, :inline, false)
    data = build_data(icon, opts)
    svg = render_embedded_svg(icon, data)

    style =
      opts
      |> Keyword.get(:style)
      |> style_with(color: color, inline: inline)
      |> style_with(span_style(mode, svg, data))

    opts =
      opts
      |> Keyword.put(:style, style)
      |> Keyword.drop([:width, :height, :rotate, :h_flip, :v_flip, :replace_ids, :id_prefix])

    :span
    |> element(opts, [])
    |> render_element()
  end

  defp transform_icon(%Icon{} = icon) do
    box = %{left: icon.left, top: icon.top, width: icon.width, height: icon.height}
    {body, box} = apply_transformations(icon.body, box, icon.h_flip, icon.v_flip, icon.rotate)
    {body, box}
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

  defp dimensions(box, opts) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)

    cond do
      is_nil(width) and is_nil(height) ->
        height = "1em"
        {calculate_size(height, box.width / box.height), height}

      is_nil(width) ->
        height = icon_size(height, box.height)
        {calculate_size(height, box.width / box.height), height}

      is_nil(height) ->
        width = icon_size(width, box.width)
        {width, calculate_size(width, box.height / box.width)}

      true ->
        {icon_size(width, box.width), icon_size(height, box.height)}
    end
  end

  defp icon_size("auto", fallback), do: fallback
  defp icon_size(value, _fallback), do: value

  defp calculate_size(size, 1.0), do: size

  defp calculate_size(size, ratio) when is_number(size),
    do: size |> Kernel.*(ratio) |> Float.ceil(2) |> normalize_number()

  defp calculate_size(size, ratio) when is_binary(size) do
    Regex.replace(~r/-?\d*\.?\d+/, size, fn value ->
      case Float.parse(value) do
        {number, ""} ->
          number
          |> Kernel.*(ratio)
          |> Float.ceil(2)
          |> format_number()

        _ ->
          value
      end
    end)
  end

  defp calculate_size(size, _ratio), do: size

  defp swap_box(box) do
    %{box | left: box.top, top: box.left, width: box.height, height: box.width}
  end

  defp viewbox(box), do: "#{box.left} #{box.top} #{box.width} #{box.height}"

  defp render_embedded_svg(icon, data) do
    data.body
    |> parse_fragment!()
    |> then(fn content ->
      {:svg,
       [
         xmlns: ~c"http://www.w3.org/2000/svg",
         viewBox: to_charlist(data.viewbox),
         width: to_charlist(to_string(icon.width)),
         height: to_charlist(to_string(icon.height))
       ], content}
    end)
    |> render_element()
  end

  defp svg_attrs(opts, data, fill) do
    [
      xmlns: ~c"http://www.w3.org/2000/svg",
      viewBox: to_charlist(data.viewbox),
      fill: to_charlist(to_string(fill)),
      "aria-hidden": ~c"true"
    ] ++ build_attrs(opts)
  end

  defp element(name, attrs, content), do: {name, build_attrs(attrs), content}

  defp render_element(element) do
    [element]
    |> :xmerl.export_simple_content(:xmerl_xml)
    |> IO.iodata_to_binary()
  end

  defp wrap(body, transforms) do
    ~s(<g transform="#{Enum.join(transforms, " ")}">#{body}</g>)
  end

  defp build_attrs(opts) do
    opts
    |> Keyword.drop([:rotate, :h_flip, :v_flip, :replace_ids, :id_prefix])
    |> Enum.reject(fn {_key, value} -> is_nil(value) or unset_keyword?(value) end)
    |> Enum.map(fn {key, value} -> {attr_name(key), to_charlist(to_string(value))} end)
  end

  defp attr_name(key), do: Map.get(@attr_names, key, key)

  defp put_default_attr(opts, key, value) do
    if Keyword.has_key?(opts, key), do: opts, else: Keyword.put(opts, key, value)
  end

  defp put_style(opts, values) do
    style = opts |> Keyword.get(:style) |> style_with(values)
    Keyword.put(opts, :style, style)
  end

  defp style_with(style, values) do
    values
    |> Enum.reduce(normalize_style(style), fn
      {_key, nil}, style ->
        style

      {:inline, false}, style ->
        style

      {:inline, true}, style ->
        append_style(style, "vertical-align:-0.125em")

      {key, value}, style ->
        append_style(style, "#{String.replace(to_string(key), "_", "-")}:#{value}")
    end)
    |> empty_to_nil()
  end

  defp span_style(:mask, svg, data) do
    [
      display: "inline-block",
      width: format_size(data.width),
      height: format_size(data.height),
      background_color: "currentColor",
      mask: "var(--svg) no-repeat 50% 50% / 100% 100%",
      "-webkit-mask": "var(--svg) no-repeat 50% 50% / 100% 100%",
      "--svg": "url(\"#{svg_to_url(svg)}\")"
    ]
  end

  defp span_style(:bg, svg, data) do
    [
      display: "inline-block",
      width: format_size(data.width),
      height: format_size(data.height),
      background: "transparent var(--svg) no-repeat 50% 50% / 100% 100%",
      "--svg": "url(\"#{svg_to_url(svg)}\")"
    ]
  end

  defp normalize_style(nil), do: nil
  defp normalize_style(style) when is_binary(style), do: String.trim_trailing(style, ";")

  defp normalize_style(style) when is_list(style) do
    style
    |> Enum.map(&style_pair/1)
    |> Enum.intersperse(";")
    |> IO.iodata_to_binary()
  end

  defp style_pair({key, value}) do
    [String.replace(to_string(key), "_", "-"), ?:, to_string(value)]
  end

  defp append_style(nil, value), do: value
  defp append_style("", value), do: value
  defp append_style(style, value), do: style <> ";" <> value

  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(""), do: nil
  defp empty_to_nil(style), do: style

  defp unset_keyword?(value) when value in @unset_keywords, do: true
  defp unset_keyword?(_), do: false

  defp replace_parsed_ids(body, prefix) do
    case parse_fragment(body) do
      {:ok, wrapper} -> render_with_replaced_ids(wrapper, prefix)
      :error -> body
    end
  end

  defp render_with_replaced_ids(wrapper, prefix) do
    replacements = wrapper |> collect_ids() |> Map.new(&{&1, "#{prefix}-#{&1}"})

    wrapper
    |> update_ids(replacements)
    |> element_content()
    |> :xmerl.export_simple_content(:xmerl_xml)
    |> IO.iodata_to_binary()
  end

  defp parse_fragment!(body) do
    {:ok, wrapper} = parse_fragment(body)
    element_content(wrapper)
  end

  defp parse_fragment(body) do
    wrapper =
      [
        ~s(<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">),
        body,
        "</svg>"
      ]
      |> IO.iodata_to_binary()
      |> String.to_charlist()

    {:ok, :xmerl_scan.string(wrapper, quiet: true) |> elem(0)}
  rescue
    _ -> :error
  catch
    :exit, _ -> :error
  end

  defp collect_ids({:xmlElement, _, _, _, _, _, _, attrs, content, _, _, _}) do
    own_ids =
      attrs
      |> Enum.filter(&(attribute_name(&1) == :id))
      |> Enum.map(&attribute_value/1)

    child_ids = content |> Enum.flat_map(&collect_ids/1)
    Enum.uniq(own_ids ++ child_ids)
  end

  defp collect_ids(_node), do: []

  defp update_ids(
         {:xmlElement, name, expanded, nsinfo, namespace, parents, pos, attrs, content, language,
          xmlbase, elementdef},
         replacements
       ) do
    attrs = Enum.map(attrs, &update_attribute(&1, replacements))
    content = Enum.map(content, &update_ids(&1, replacements))

    {:xmlElement, name, expanded, nsinfo, namespace, parents, pos, attrs, content, language,
     xmlbase, elementdef}
  end

  defp update_ids(node, _replacements), do: node

  defp update_attribute(
         {:xmlAttribute, name, expanded, nsinfo, namespace, parents, pos, language, value,
          normalized},
         replacements
       ) do
    value =
      value |> to_string() |> update_attribute_value(name, replacements) |> String.to_charlist()

    {:xmlAttribute, name, expanded, nsinfo, namespace, parents, pos, language, value, normalized}
  end

  defp update_attribute(attribute, _replacements), do: attribute

  defp update_attribute_value(value, :id, replacements), do: Map.get(replacements, value, value)

  defp update_attribute_value(value, _name, replacements) do
    Enum.reduce(replacements, value, fn {id, replacement}, value ->
      value
      |> String.replace("##{id}", "##{replacement}")
      |> String.replace(";#{id}", ";#{replacement}")
      |> replace_animation_reference(id, replacement)
    end)
  end

  defp replace_animation_reference(value, id, replacement) do
    case String.split(value, ".", parts: 2) do
      [^id, rest] -> replacement <> "." <> rest
      _ -> value
    end
  end

  defp element_content({:xmlElement, _, _, _, _, _, _, _, content, _, _, _}), do: content

  defp attribute_name({:xmlAttribute, name, _, _, _, _, _, _, _, _}), do: name
  defp attribute_value({:xmlAttribute, _, _, _, _, _, _, _, value, _}), do: to_string(value)

  defp unique_id_prefix do
    "iconify-#{System.unique_integer([:positive])}"
  end

  defp svg_to_url(svg) do
    URI.encode(svg, &URI.char_unreserved?/1)
  end

  defp normalize_number(value) when is_float(value) do
    if value == trunc(value), do: trunc(value), else: value
  end

  defp normalize_number(value), do: value

  defp format_size(value) when is_number(value), do: format_number(value) <> "px"
  defp format_size(value), do: value

  defp format_number(value) when is_float(value) do
    if value == trunc(value), do: Integer.to_string(trunc(value)), else: Float.to_string(value)
  end

  defp format_number(value), do: to_string(value)
end
