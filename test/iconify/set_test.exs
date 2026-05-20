defmodule Iconify.SetTest do
  use ExUnit.Case, async: true
  doctest Iconify.Set

  alias Iconify.Set

  @sample_json """
  {
    "prefix": "test",
    "width": 24,
    "height": 24,
    "icons": {
      "user": {
        "body": "<path d=\\"M10\\"/>"
      },
      "home": {
        "body": "<path d=\\"M20\\"/>",
        "width": 20,
        "height": 20
      }
    },
    "aliases": {
      "person": {
        "parent": "user"
      },
      "profile": {
        "parent": "person",
        "width": 32,
        "hFlip": true,
        "rotate": 1
      }
    }
  }
  """

  describe "parse/1" do
    test "parses valid IconifyJSON" do
      assert {:ok, set} = Set.parse(@sample_json)

      assert set.prefix == "test"
      assert set.width == 24
      assert set.height == 24
      assert map_size(set.icons) == 2
      assert map_size(set.aliases) == 2
    end

    test "uses default dimensions for icons" do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, user} = Set.get(set, "user")

      assert user.width == 24
      assert user.height == 24
    end

    test "respects icon-specific dimensions" do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, home} = Set.get(set, "home")

      assert home.width == 20
      assert home.height == 20
    end
  end

  describe "get/2" do
    setup do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, set: set}
    end

    test "returns icon by name", %{set: set} do
      assert {:ok, icon} = Set.get(set, "user")
      assert icon.name == "user"
      assert icon.body == ~s(<path d="M10"/>)
    end

    test "resolves aliases", %{set: set} do
      assert {:ok, icon} = Set.get(set, "person")
      assert icon.name == "person"
    end

    test "resolves alias chains with dimensions and transformations", %{set: set} do
      assert {:ok, icon} = Set.get(set, "profile")
      assert icon.name == "profile"
      assert icon.body == ~s(<path d="M10"/>)
      assert icon.width == 32
      assert icon.height == 24
      assert icon.h_flip
      assert icon.rotate == 1
    end

    test "returns error for unknown icon", %{set: set} do
      assert :error = Set.get(set, "nonexistent")
    end
  end

  describe "get!/2" do
    setup do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, set: set}
    end

    test "returns icon by name", %{set: set} do
      icon = Set.get!(set, "user")
      assert icon.name == "user"
    end

    test "raises for unknown icon", %{set: set} do
      assert_raise RuntimeError, ~r/not found/, fn ->
        Set.get!(set, "nonexistent")
      end
    end
  end

  describe "list/1 and list_all/1" do
    setup do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, set: set}
    end

    test "list/1 returns icon names without aliases", %{set: set} do
      names = Set.list(set)
      assert "user" in names
      assert "home" in names
      refute "person" in names
    end

    test "list_all/1 includes aliases", %{set: set} do
      names = Set.list_all(set)
      assert "user" in names
      assert "home" in names
      assert "person" in names
    end
  end

  describe "has?/2" do
    setup do
      {:ok, set} = Set.parse(@sample_json)
      {:ok, set: set}
    end

    test "returns true for existing icons", %{set: set} do
      assert Set.has?(set, "user")
      assert Set.has?(set, "home")
    end

    test "returns true for aliases", %{set: set} do
      assert Set.has?(set, "person")
    end

    test "returns false for unknown icons", %{set: set} do
      refute Set.has?(set, "nonexistent")
    end
  end

  describe "count/1" do
    test "returns number of icons" do
      {:ok, set} = Set.parse(@sample_json)
      assert Set.count(set) == 2
    end
  end
end
