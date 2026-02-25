defmodule Iconify.IconTest do
  use ExUnit.Case, async: true
  doctest Iconify.Icon

  alias Iconify.Icon

  describe "new/3" do
    test "creates icon with required fields" do
      icon = Icon.new("user", %{"body" => "<path/>"})

      assert icon.name == "user"
      assert icon.body == "<path/>"
      assert icon.width == 24
      assert icon.height == 24
    end

    test "uses dimensions from data" do
      icon = Icon.new("user", %{"body" => "<path/>", "width" => 20, "height" => 16})

      assert icon.width == 20
      assert icon.height == 16
    end

    test "uses dimensions from defaults" do
      icon = Icon.new("user", %{"body" => "<path/>"}, width: 32, height: 32)

      assert icon.width == 32
      assert icon.height == 32
    end

    test "data takes precedence over defaults" do
      icon = Icon.new("user", %{"body" => "<path/>", "width" => 20}, width: 32, height: 32)

      assert icon.width == 20
      assert icon.height == 32
    end
  end

  describe "viewbox/1" do
    test "returns viewBox string" do
      icon = %Icon{name: "test", body: "", width: 24, height: 24, left: 0, top: 0}
      assert Icon.viewbox(icon) == "0 0 24 24"
    end

    test "includes left and top offsets" do
      icon = %Icon{name: "test", body: "", width: 24, height: 24, left: 2, top: 4}
      assert Icon.viewbox(icon) == "2 4 24 24"
    end
  end
end
