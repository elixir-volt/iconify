defmodule Iconify.SVGTest do
  use ExUnit.Case, async: true

  alias Iconify.{Icon, SVG}

  describe "render/2" do
    test "renders basic SVG" do
      icon = %Icon{name: "user", body: ~s(<path d="M10"/>), width: 24, height: 24}
      svg = SVG.render(icon)

      assert svg =~ ~s(<svg)
      assert svg =~ ~s(xmlns="http://www.w3.org/2000/svg")
      assert svg =~ ~s(viewBox="0 0 24 24")
      assert svg =~ ~s(<path d="M10"/>)
      assert svg =~ ~s(</svg>)
    end

    test "adds class attribute" do
      icon = %Icon{name: "user", body: "", width: 24, height: 24}
      svg = SVG.render(icon, class: "w-6 h-6")

      assert svg =~ ~s(class="w-6 h-6")
    end

    test "escapes attribute values" do
      icon = %Icon{name: "user", body: "", width: 24, height: 24}
      svg = SVG.render(icon, class: ~s(foo "bar"))

      assert svg =~ ~s(class="foo &quot;bar&quot;")
    end

    test "respects custom viewBox" do
      icon = %Icon{name: "user", body: "", width: 20, height: 20, left: 2, top: 2}
      svg = SVG.render(icon)

      assert svg =~ ~s(viewBox="2 2 20 20")
    end

    test "uses Iconify dimension defaults and preserves aspect ratio" do
      icon = %Icon{name: "wide", body: "", width: 32, height: 16}

      assert SVG.render(icon) =~ ~s(width="2em")
      assert SVG.render(icon, height: 24) =~ ~s(width="48")
      assert SVG.render(icon, width: "2rem") =~ ~s(height="1rem")
      refute SVG.render(icon, width: "unset") =~ ~s(width="unset")
    end

    test "adds color and inline style" do
      icon = %Icon{name: "user", body: "", width: 24, height: 24}
      svg = SVG.render(icon, color: "red", inline: true)

      assert svg =~ ~s(style="color:red;vertical-align:-0.125em")
    end

    test "replaces ids in body references" do
      icon = %Icon{
        name: "gradient",
        body: ~s|<defs><linearGradient id="a"></linearGradient></defs><path fill="url(#a)"/>|,
        width: 24,
        height: 24
      }

      svg = SVG.render(icon, id_prefix: "icon")

      assert svg =~ ~s(id="icon-a")
      assert svg =~ ~s|url(#icon-a)|
      refute svg =~ ~s(id="a")
    end

    test "can render CSS mask mode" do
      icon = %Icon{name: "user", body: ~s(<path d="M10"/>), width: 24, height: 24}
      html = SVG.render(icon, mode: "mask", class: "icon")

      assert html =~ ~s(<span)
      assert html =~ ~s(class="icon")
      assert String.contains?(html, "mask" <> <<58, 118, 97, 114, 40, 45, 45, 115, 118, 103, 41>>)
    end
  end
end
