defmodule IconifyTest do
  use ExUnit.Case, async: true
  doctest Iconify

  alias Iconify.Icon

  describe "to_svg/2" do
    test "delegates SVG rendering" do
      icon = %Icon{name: "user", body: ~s(<path d="M10"/>), width: 24, height: 24}
      assert Iconify.to_svg(icon) == Iconify.SVG.render(icon)
    end
  end

  describe "parse_name/1" do
    test "parses valid icon names" do
      assert Iconify.parse_name("heroicons:user") == {:ok, "heroicons", "user"}
      assert Iconify.parse_name("mdi:home") == {:ok, "mdi", "home"}
      assert Iconify.parse_name("lucide:arrow-left") == {:ok, "lucide", "arrow-left"}
    end

    test "returns error for invalid names" do
      assert Iconify.parse_name("invalid") == :error
      assert Iconify.parse_name(":user") == :error
      assert Iconify.parse_name("heroicons:") == :error
      assert Iconify.parse_name("") == :error
    end
  end
end
