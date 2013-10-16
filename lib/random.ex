defmodule Random do
  @moduledoc """
  A ruby-like wrapper for the random module of Erlang.
  This module is not cryptographically strong as the random
  module of Erlang.
  """

  @type ran :: { integer, integer, integer }

  @doc """
  Seeds random number generation with default (fixed) values
  in the process dictionary, and returns the old state.
  """
  @spec seed :: :undefined | ran
  def seed do
    :random.seed
  end

  @doc """
  `Random.seed(seed)` is equivalent to `Random.srand(seed)`
  """
  @spec seed({ integer, integer, integer }) :: :undefined | ran
  def seed(seed) do
    srand(seed)
  end

  @doc """
  `Random.seed(x, y, z)` is equivalent to `Random.srand(x, y, z)`
  """
  @spec seed(integer, integer, integer) :: :undefined | ran
  def seed(x, y, z) do
    srand(x, y, z)
  end

  @doc """
  Returns the default seed.
  """
  @spec default_seed :: ran
  def default_seed do
    :random.seed0
  end

  @doc """
  Returns a random-generated seed.
  """
  @spec new_seed :: ran
  def new_seed do
    { rand(9999), rand(9999), rand(99999) }
  end

  @doc """
  `Random.srand` is equivalent to `Random.srand(Random.new_seed)`
  """
  @spec srand :: :undefined | ran
  def srand do
    :random.seed(new_seed)
  end

  @doc """
  `Random.srand({ x, y, z })` is equivalent to `Random.srand(x, y, z)`
  """
  @spec srand({ integer, integer, integer }) :: :undefined | ran
  def srand({ x, y, z }) do
    srand(x, y, z)
  end

  @doc """
  Seeds random number generation with integer values in the
  process dictionary, and returns the old state.

  ## Examples

      iex> Random.srand(:erlang.now)
  """
  @spec srand(integer, integer, integer) :: :undefined | ran
  def srand(a, b, c) when is_integer(a) and is_integer(b) and is_integer(c) do
    :random.seed(a, b, c)
  end

  @doc """
  Returns a random float uniformly distributed between `0.0`
  and `1.0`, updating the state in the process dictionary.

  ## Examples

      iex> Random.rand
      0.4435846174457203
  """
  @spec rand :: float
  def rand do
    :random.uniform
  end

  @doc """
  `Random.random` is equivalent to `Random.rand`
  """
  @spec random :: float
  def random, do: rand

  @doc """
  When `max` is an integer, `rand` returns a random integer greater
  than or equal to `0` and less than `max`.

  ## Examples

      iex> Random.rand(3)
      1

  When `max` is a float, `rand` returns a random floating point
  number between `0.0` and `max`, including `0.0` and excluding
  `max`.

  ## Examples

      iex> Random.rand(1.5)
      1.460028286003411

  When `max` is a range, `rand` returns a random number where
  `Enum.member?(range, number) == true`.

  ## Examples

      iex> Random.rand(5 .. 9)
      4
      iex> Random.rand(5.0 .. 9.0)
      6.309692303046198
  """
  @spec rand(integer | float | Range.t) :: integer | float

  def rand(0) do
    0
  end

  def rand(max) when is_float(max) do
    res = :random.uniform * max

    if res >= max do
      rand(max)
    else
      res
    end
  end

  def rand(min .. max) when is_number(min) and is_number(max) and is_integer(min) == is_integer(max) do
    rand(:erlang.min(min, max), :erlang.max(min, max))
  end

  def rand(min .. max) when is_number(min) and is_number(max) do
    if min == trunc(min) do
      if max == trunc(max) do
        rand(trunc(:erlang.min(min, max)), trunc(:erlang.max(min, max)))
      else
        rand(:erlang.float(:erlang.min(min, max)), :erlang.float(:erlang.max(min, max)))
      end
    else
      rand(:erlang.float(:erlang.min(min, max)), :erlang.float(:erlang.max(min, max)))
    end
  end

  def rand(max) when is_integer(max) and max > 0 do
    :random.uniform(max) - 1
  end

  @doc """
  `Random.random(max)` is equivalent to `Random.rand(max)`.
  """
  @spec random(integer | float | Range.t) :: integer | float
  def random(max), do: rand(max)

  @doc """
  Returns a random binary containing `size` bytes.

  ## Examples

      iex> Random.bytes(10)
      <<113, 185, 242, 128, 79, 152, 234, 170, 122, 152>>
  """
  @spec bytes(non_neg_integer) :: binary

  def bytes(0) do
    ""
  end

  def bytes(size) when is_integer(size) and size > 0 do
    bytes(size, "")
  end

  defp bytes(0, res) do
    res
  end

  defp bytes(b, res) do
    bytes(b - 1, << res :: binary(), rand(0, 255) :: 8>>)
  end

  defp rand(min, max) when min == max do
    min
  end

  defp rand(1, max) do
    :random.uniform(max)
  end

  defp rand(min, max) when is_integer(min) do
    min = min - 1
    min + :random.uniform(max - min)
  end

  defp rand(min, max) when is_float(min) do
    res = (:random.uniform * (max - min)) + min

    if res > max or res < min do
      rand(min, max)
    else
      res
    end
  end
end
