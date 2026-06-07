defmodule Iconify.Icon do
  @moduledoc """
  Represents a single normalized Iconify icon.
  """

  use JSONCodec, case: :camel, fast_path: :json

  @derive Jason.Encoder
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

  codec(:rotate, transform: :normalize_rotate)

  @doc false
  def normalize_rotate(value) when is_integer(value), do: Integer.mod(value, 4)
  def normalize_rotate(_value), do: 0

  @doc """
  Returns the viewBox string for this icon.
  """
  @spec viewbox(t()) :: String.t()
  def viewbox(%__MODULE__{left: left, top: top, width: width, height: height}) do
    "#{left} #{top} #{width} #{height}"
  end
end
