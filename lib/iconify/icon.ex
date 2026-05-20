defmodule Iconify.Icon do
  @moduledoc """
  Represents a single normalized Iconify icon.
  """

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          name: String.t(),
          body: String.t(),
          width: pos_integer(),
          height: pos_integer(),
          left: integer(),
          top: integer(),
          rotate: integer(),
          h_flip: boolean(),
          v_flip: boolean(),
          hidden: boolean()
        }

  @enforce_keys [:name, :body]
  defstruct [
    :name,
    :body,
    width: 16,
    height: 16,
    left: 0,
    top: 0,
    rotate: 0,
    h_flip: false,
    v_flip: false,
    hidden: false
  ]

  @doc """
  Returns the viewBox string for this icon.
  """
  @spec viewbox(t()) :: String.t()
  def viewbox(%__MODULE__{left: left, top: top, width: width, height: height}) do
    "#{left} #{top} #{width} #{height}"
  end
end
