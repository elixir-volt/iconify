defmodule Iconify.Set do
  @moduledoc """
  Represents an Iconify icon set (collection of icons with a common prefix).
  """

  use JSONCodec, case: :camel, fast_path: :json

  alias Iconify.Icon

  @derive Jason.Encoder
  defstruct [
    :prefix,
    icons: %{},
    aliases: %{},
    width: 16,
    height: 16,
    left: 0,
    top: 0,
    provider: nil,
    info: nil,
    chars: nil,
    categories: nil,
    themes: nil,
    prefixes: nil,
    suffixes: nil,
    last_modified: nil,
    not_found: []
  ]

  @type t :: %__MODULE__{
          prefix: String.t(),
          icons: %{String.t() => Icon.t()},
          aliases: %{String.t() => map()},
          width: pos_integer(),
          height: pos_integer(),
          left: integer(),
          top: integer(),
          provider: String.t() | nil,
          info: map() | nil,
          chars: map() | nil,
          categories: map() | nil,
          themes: map() | nil,
          prefixes: map() | nil,
          suffixes: map() | nil,
          last_modified: integer() | nil,
          not_found: [String.t()]
        }

  codec(:icons, decode_values: :icon_value, values_source: :icon_defaults)
  codec(:aliases, values: :alias_value)
  codec(:not_found, as: "not_found")

  @alias_keys [:parent, :left, :top, :width, :height, :rotate, :h_flip, :v_flip, :hidden]

  @doc false
  def icon_value(name, data, defaults) do
    %Icon{
      name: name,
      body: Map.fetch!(data, "body"),
      width: Map.get(data, "width", Map.get(defaults, "width", 16)),
      height: Map.get(data, "height", Map.get(defaults, "height", 16)),
      left: Map.get(data, "left", Map.get(defaults, "left", 0)),
      top: Map.get(data, "top", Map.get(defaults, "top", 0)),
      rotate: Icon.normalize_rotate(Map.get(data, "rotate", Map.get(defaults, "rotate", 0))),
      h_flip: Map.get(data, "hFlip", Map.get(defaults, "hFlip", false)),
      v_flip: Map.get(data, "vFlip", Map.get(defaults, "vFlip", false)),
      hidden: Map.get(data, "hidden", false)
    }
  end

  @doc false
  def alias_value(_name, data, _source) do
    data
    |> normalize_map()
    |> Map.take(@alias_keys)
  end

  @doc """
  Loads an icon set from a JSON file.
  """
  @spec load(Path.t()) :: {:ok, t()} | {:error, term()}
  def load(path) do
    with {:ok, contents} <- File.read(path) do
      parse(contents)
    end
  end

  @doc """
  Loads an icon set from a JSON file, raising on error.
  """
  @spec load!(Path.t()) :: t()
  def load!(path) do
    case load(path) do
      {:ok, set} -> set
      {:error, reason} -> raise "Failed to load icon set from #{path}: #{inspect(reason)}"
    end
  end

  @doc """
  Parses an icon set from a JSON string (IconifyJSON format).
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(json) when is_binary(json) do
    with {:ok, data} <- Jason.decode(json) do
      parse_data(data)
    end
  end

  @doc """
  Parses an icon set from decoded IconifyJSON data.
  """
  @spec parse_data(map()) :: {:ok, t()} | {:error, term()}
  def parse_data(data) when is_map(data) do
    from_map(data)
  end

  @doc """
  Gets an icon from the set by name, resolving aliases and alias transformations.
  """
  @spec get(t(), String.t()) :: {:ok, Icon.t()} | :error
  def get(%__MODULE__{} = set, name) when is_binary(name) do
    case resolve_icon(set, name, MapSet.new()) do
      {:ok, icon} -> {:ok, %{icon | name: name}}
      :error -> :error
    end
  end

  @doc """
  Gets an icon from the set by name, raising if not found.
  """
  @spec get!(t(), String.t()) :: Icon.t()
  def get!(%__MODULE__{} = set, name) do
    case get(set, name) do
      {:ok, icon} -> icon
      :error -> raise "Icon #{inspect(name)} not found in set #{set.prefix}"
    end
  end

  @doc """
  Checks if an icon exists in the set.
  """
  @spec has?(t(), String.t()) :: boolean()
  def has?(%__MODULE__{} = set, name) do
    Map.has_key?(set.icons, name) or Map.has_key?(set.aliases, name)
  end

  @doc """
  Lists all icon names in the set (excluding aliases).
  """
  @spec list(t()) :: [String.t()]
  def list(%__MODULE__{icons: icons}) do
    Map.keys(icons)
  end

  @doc """
  Lists all icon names including aliases.
  """
  @spec list_all(t()) :: [String.t()]
  def list_all(%__MODULE__{icons: icons, aliases: aliases}) do
    Map.keys(icons) ++ Map.keys(aliases)
  end

  @doc """
  Returns the number of icons in the set (excluding aliases).
  """
  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{icons: icons}) do
    map_size(icons)
  end

  defp resolve_icon(set, name, seen) do
    cond do
      MapSet.member?(seen, name) ->
        :error

      icon = Map.get(set.icons, name) ->
        {:ok, icon}

      alias_data = Map.get(set.aliases, name) ->
        resolve_alias(set, alias_data, MapSet.put(seen, name))

      true ->
        :error
    end
  end

  defp resolve_alias(set, %{parent: parent} = alias_data, seen) do
    with {:ok, parent_icon} <- resolve_icon(set, parent, seen) do
      {:ok, merge_alias(parent_icon, alias_data)}
    end
  end

  defp resolve_alias(_set, _alias_data, _seen), do: :error

  defp merge_alias(%Icon{} = icon, alias_data) do
    icon
    |> maybe_put(alias_data, :left)
    |> maybe_put(alias_data, :top)
    |> maybe_put(alias_data, :width)
    |> maybe_put(alias_data, :height)
    |> maybe_put(alias_data, :hidden)
    |> Map.update!(:rotate, &Integer.mod(&1 + Map.get(alias_data, :rotate, 0), 4))
    |> Map.update!(:h_flip, &xor(&1, Map.get(alias_data, :h_flip, false)))
    |> Map.update!(:v_flip, &xor(&1, Map.get(alias_data, :v_flip, false)))
  end

  defp maybe_put(data, source, key) do
    case Map.fetch(source, key) do
      {:ok, value} -> Map.put(data, key, value)
      :error -> data
    end
  end

  defp xor(left, right), do: !!left != !!right

  @doc false
  def icon_defaults(data) do
    Map.take(data, ["left", "top", "width", "height", "rotate", "hFlip", "vFlip"])
  end

  defp normalize_map(map) do
    Map.new(map, fn {key, value} -> {normalize_key(key), value} end)
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    key
    |> Macro.underscore()
    |> String.to_existing_atom()
  rescue
    ArgumentError -> key
  end
end
