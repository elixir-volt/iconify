defmodule Iconify.Set do
  @moduledoc """
  Represents an Iconify icon set (collection of icons with a common prefix).

  ## Loading Icon Sets

      # From a file
      {:ok, set} = Iconify.Set.load("path/to/heroicons.json")

      # From a JSON string
      {:ok, set} = Iconify.Set.parse(json_string)

  ## Getting Icons

      {:ok, icon} = Iconify.Set.get(set, "user")
      icon = Iconify.Set.get!(set, "user")

  """

  alias Iconify.Icon

  @type t :: %__MODULE__{
          prefix: String.t(),
          icons: %{String.t() => Icon.t()},
          aliases: %{String.t() => String.t()},
          width: pos_integer(),
          height: pos_integer()
        }

  @enforce_keys [:prefix]
  defstruct [
    :prefix,
    icons: %{},
    aliases: %{},
    width: 24,
    height: 24
  ]

  @doc """
  Loads an icon set from a JSON file.

  ## Examples

      {:ok, set} = Iconify.Set.load("priv/iconify/heroicons.json")

  """
  @spec load(Path.t()) :: {:ok, t()} | {:error, term()}
  def load(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, set} <- parse(contents) do
      {:ok, set}
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

  ## Examples

      json = ~s({"prefix": "heroicons", "icons": {"user": {"body": "<path/>"}}})
      {:ok, set} = Iconify.Set.parse(json)

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(json) when is_binary(json) do
    with {:ok, data} <- Jason.decode(json) do
      parse_data(data)
    end
  end

  @doc """
  Parses an icon set from a decoded JSON map.
  """
  @spec parse_data(map()) :: {:ok, t()} | {:error, term()}
  def parse_data(data) when is_map(data) do
    prefix = Map.fetch!(data, "prefix")
    default_width = data["width"] || 24
    default_height = data["height"] || 24

    defaults = [
      width: default_width,
      height: default_height,
      left: data["left"] || 0,
      top: data["top"] || 0
    ]

    icons =
      data
      |> Map.get("icons", %{})
      |> Map.new(fn {name, icon_data} ->
        {name, Icon.new(name, icon_data, defaults)}
      end)

    aliases =
      data
      |> Map.get("aliases", %{})
      |> Map.new(fn {name, alias_data} ->
        {name, alias_data["parent"]}
      end)

    {:ok,
     %__MODULE__{
       prefix: prefix,
       icons: icons,
       aliases: aliases,
       width: default_width,
       height: default_height
     }}
  rescue
    e -> {:error, e}
  end

  @doc """
  Gets an icon from the set by name, resolving aliases.

  ## Examples

      {:ok, icon} = Iconify.Set.get(set, "user")
      :error = Iconify.Set.get(set, "nonexistent")

  """
  @spec get(t(), String.t()) :: {:ok, Icon.t()} | :error
  def get(%__MODULE__{} = set, name) when is_binary(name) do
    case Map.fetch(set.icons, name) do
      {:ok, icon} ->
        {:ok, icon}

      :error ->
        case Map.fetch(set.aliases, name) do
          {:ok, parent} -> get(set, parent)
          :error -> :error
        end
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
end
