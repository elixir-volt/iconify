defmodule Iconify.IconTest do
  use ExUnit.Case, async: true
  doctest Iconify.Icon

  alias Iconify.Icon

  describe "struct defaults" do
    test "sets Iconify defaults" do
      icon = %Icon{name: "user", body: "<path/>"}

      assert icon.name == "user"
      assert icon.body == "<path/>"
      assert icon.width == 16
      assert icon.height == 16
      assert icon.left == 0
      assert icon.top == 0
      assert icon.rotate == 0
      refute icon.h_flip
      refute icon.v_flip
      refute icon.hidden
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
