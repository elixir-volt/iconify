defmodule IconifyTest do
  use ExUnit.Case, async: true
  doctest Iconify

  alias Iconify.Icon

  describe "to_svg/2" do
    test "renders basic SVG" do
      icon = %Icon{name: "user", body: ~s(<path d="M10"/>), width: 24, height: 24}
      svg = Iconify.to_svg(icon)

      assert svg =~ ~s(<svg)
      assert svg =~ ~s(xmlns="http://www.w3.org/2000/svg")
      assert svg =~ ~s(viewBox="0 0 24 24")
      assert svg =~ ~s(<path d="M10"/>)
      assert svg =~ ~s(</svg>)
    end

    test "adds class attribute" do
      icon = %Icon{name: "user", body: "", width: 24, height: 24}
      svg = Iconify.to_svg(icon, class: "w-6 h-6")

      assert svg =~ ~s(class="w-6 h-6")
    end

    test "escapes attribute values" do
      icon = %Icon{name: "user", body: "", width: 24, height: 24}
      svg = Iconify.to_svg(icon, class: ~s(foo "bar"))

      assert svg =~ ~s(class="foo &quot;bar&quot;")
    end

    test "respects custom viewBox" do
      icon = %Icon{name: "user", body: "", width: 20, height: 20, left: 2, top: 2}
      svg = Iconify.to_svg(icon)

      assert svg =~ ~s(viewBox="2 2 20 20")
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
