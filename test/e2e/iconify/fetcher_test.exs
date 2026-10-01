defmodule Iconify.E2E.FetcherTest do
  # Talks to the Iconify API. Run with `mix test.e2e`.
  use ExUnit.Case, async: true

  alias Iconify.Fetcher

  @moduletag :e2e

  setup do
    {:ok, _} = Application.ensure_all_started(:req)
    :ok
  end

  test "fetch_icons/2 leaves out names the set doesn't have" do
    assert {:ok, icons} = Fetcher.fetch_icons("lucide", ["mail", "no-such-icon-anywhere"])
    assert Map.keys(icons) == ["mail"]
    assert icons["mail"].body =~ "<"
  end

  test "fetch_icon/2 reports an unknown name as not found" do
    assert {:ok, %Iconify.Icon{}} = Fetcher.fetch_icon("lucide", "layer-arrow-up")
    assert Fetcher.fetch_icon("lucide", "no-such-icon-anywhere") == {:error, :not_found}
  end
end
