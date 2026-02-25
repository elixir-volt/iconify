defmodule Iconify.Fetcher do
  @moduledoc """
  Fetches icon data from Iconify sources.

  Requires the `req` dependency to be installed.

  ## Sources

    * **NPM** - Fetches complete icon sets from `@iconify-json/{prefix}` packages
    * **API** - Fetches individual icons from api.iconify.design

  ## Examples

      # Fetch entire icon set
      {:ok, set} = Iconify.Fetcher.fetch_set("heroicons")

      # Fetch specific icons
      {:ok, icons} = Iconify.Fetcher.fetch_icons("heroicons", ["user", "home"])

  """

  alias Iconify.{Icon, Set}

  @npm_registry "https://registry.npmjs.org"
  @iconify_api "https://api.iconify.design"

  @doc """
  Fetches a complete icon set from NPM.

  Downloads the `@iconify-json/{prefix}` package and parses its icons.json.

  ## Examples

      {:ok, set} = Iconify.Fetcher.fetch_set("heroicons")
      {:ok, set} = Iconify.Fetcher.fetch_set("mdi")

  """
  @spec fetch_set(String.t()) :: {:ok, Set.t()} | {:error, term()}
  def fetch_set(prefix) when is_binary(prefix) do
    ensure_req!()

    with {:ok, tarball_url} <- get_tarball_url(prefix),
         {:ok, json} <- download_and_extract_icons(tarball_url) do
      Set.parse(json)
    end
  end

  @doc """
  Fetches specific icons from the Iconify API.

  Returns a map of icon name to Icon struct.

  ## Examples

      {:ok, icons} = Iconify.Fetcher.fetch_icons("heroicons", ["user", "home"])
      # => %{"user" => %Icon{}, "home" => %Icon{}}

  """
  @spec fetch_icons(String.t(), [String.t()]) :: {:ok, %{String.t() => Icon.t()}} | {:error, term()}
  def fetch_icons(prefix, names) when is_binary(prefix) and is_list(names) do
    ensure_req!()

    icons_param = Enum.join(names, ",")
    url = "#{@iconify_api}/#{prefix}.json?icons=#{icons_param}"

    with {:ok, data} <- req_get_json(url) do
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

      {:ok, icons}
    end
  end

  @doc """
  Fetches a single icon from the Iconify API.

  ## Examples

      {:ok, icon} = Iconify.Fetcher.fetch_icon("heroicons", "user")

  """
  @spec fetch_icon(String.t(), String.t()) :: {:ok, Icon.t()} | {:error, term()}
  def fetch_icon(prefix, name) when is_binary(prefix) and is_binary(name) do
    case fetch_icons(prefix, [name]) do
      {:ok, icons} ->
        case Map.fetch(icons, name) do
          {:ok, icon} -> {:ok, icon}
          :error -> {:error, :not_found}
        end

      error ->
        error
    end
  end

  @doc """
  Returns the URL for an icon set's NPM package info.
  """
  @spec npm_package_url(String.t()) :: String.t()
  def npm_package_url(prefix) do
    "#{@npm_registry}/@iconify-json/#{prefix}"
  end

  defp get_tarball_url(prefix) do
    url = npm_package_url(prefix)

    with {:ok, data} <- req_get_json(url) do
      latest = data["dist-tags"]["latest"]
      tarball = data["versions"][latest]["dist"]["tarball"]
      {:ok, tarball}
    end
  end

  defp download_and_extract_icons(tarball_url) do
    with {:ok, body} <- req_get_binary(tarball_url) do
      extract_icons_json(body)
    end
  end

  defp extract_icons_json(tarball_binary) do
    with {:ok, files} <- :erl_tar.extract({:binary, tarball_binary}, [:compressed, :memory]) do
      files
      |> Enum.find(fn {path, _content} ->
        path |> to_string() |> String.ends_with?("icons.json")
      end)
      |> case do
        {_path, content} -> {:ok, to_string(content)}
        nil -> {:error, :icons_json_not_found}
      end
    end
  end

  defp req_get_json(url) do
    case Req.get(url) do
      {:ok, %{status: 200, body: body}} when is_map(body) -> {:ok, body}
      {:ok, %{status: 200, body: body}} when is_binary(body) -> Jason.decode(body)
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status}} -> {:error, {:http_error, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp req_get_binary(url) do
    case Req.get(url, decode_body: false) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status}} -> {:error, {:http_error, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_req! do
    unless Code.ensure_loaded?(Req) do
      raise """
      The :req dependency is required for fetching icons.

      Add it to your mix.exs:

          {:req, "~> 0.5"}
      """
    end
  end
end
