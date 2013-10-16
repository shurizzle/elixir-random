defprotocol Random.Generator do
  @doc """
  Generate a random float between `0.0` and `1.0`
  """
  @spec rand(t) :: float
  def rand(self)

  @doc """
  Generate a random number between `0` and `max` if `max`
  is a number, contained in `range` if `range` is a range.
  """
  @spec rand(t, integer | float | Range.t) :: integer | float
  def rand(self, max_or_range)

  @doc """
  Generate a random binary containing `size` bytes.
  """
  @spec bytes(t, non_neg_integer) :: binary
  def bytes(self, size)
end

defmodule Random.Generator.Behaviour do
  defmacro __using__(_) do
    quote do
      defdelegate bytes(self, size), to: Random.Generator.Behaviour
      defdelegate rand(self, max), to: Random.Generator.Behaviour

      defoverridable [bytes: 2, rand: 2]
    end
  end

  @type t :: Random.Generator.t

  @doc false
  @spec rand(t, integer | float | Range.t) :: integer | float

  def rand(_, 0) do
    0
  end

  def rand(_, 0.0) do
    0.0
  end

  def rand(self, max) when is_integer(max) and max > 0 do
    trunc(Random.Generator.rand(self) * max)
  end

  def rand(self, max) when is_float(max) and max > 0 do
    res = Random.Generator.rand(self) * max

    if res >= max do
      rand(self, max)
    else
      res
    end
  end

  def rand(self, min .. max) when is_number(min) and is_number(max) and is_integer(min) == is_integer(max) do
    rand(self, :erlang.min(min, max), :erlang.max(min, max))
  end

  def rand(self, min .. max) when is_number(min) and is_number(max) do
    if min == trunc(min) do
      if max == trunc(max) do
        rand(self, trunc(:erlang.min(min, max)), trunc(:erlang.max(min, max)))
      else
        rand(self, :erlang.float(:erlang.min(min, max)), :erlang.float(:erlang.max(min, max)))
      end
    else
      rand(self, :erlang.float(:erlang.min(min, max)), :erlang.float(:erlang.max(min, max)))
    end
  end

  defp rand(_, min, max) when min == max do
    min
  end

  defp rand(self, 1, max) do
    rand(self, max) + 1
  end

  defp rand(self, min, max) when is_integer(min) do
    min + rand(self, max - min + 1)
  end

  defp rand(self, min, max) when is_float(min) do
    res = (Random.Generator.rand(self) * (max - min)) + min

    if res > max or res < min do
      rand(self, min, max)
    else
      res
    end
  end

  @doc false
  @spec bytes(t, non_neg_integer) :: binary

  def bytes(_, 0) do
    ""
  end

  def bytes(self, size) when is_integer(size) and size > 0 do
    bytes(self, size, "")
  end

  defp bytes(_, 0, res) do
    res
  end

  defp bytes(self, b, res) do
    bytes(b - 1, << res :: binary(), Random.Generator.rand(self, 0 .. 255) :: 8 >>)
  end
end
