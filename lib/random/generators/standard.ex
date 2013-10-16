defmodule Random.Generator.Standard do
  @moduledoc """
  This module wraps a random number generator using `:random.uniform_s/1`
  and `:random.uniform_s/2`
  """

  use GenServer.Behaviour

  @opaque t :: record

  if System.get_env("ELIXIR_NO_NIF") do
    defrecordp :wrap, __MODULE__, pid: nil
  else
    defrecordp :wrap, __MODULE__, pid: nil, reference: nil
  end

  @doc false
  def init(seed) do
    { :ok, seed }
  end

  @doc false
  def handle_call(:rand, _from, state) do
    { res, state } = :random.uniform_s(state)
    { :reply, res, state }
  end

  @doc false
  def handle_call({ :rand, n }, _from, state) do
    { res, state } = :random.uniform_s(n, state)
    { :reply, res, state }
  end

  @doc false
  def handle_info(:stop, state) do
    { :stop, :normal, state }
  end

  @spec new :: t
  @spec new(Random.ran) :: t
  def new({_a, _b, _c} = seed // Random.new_seed)
    when is_integer(_a) and is_integer(_b) and is_integer(_c) do
    case :gen_server.start_link(__MODULE__, seed, []) do
      { :ok, pid } ->
        wrap(unquote(if System.get_env("ELIXIR_NO_NIF") do
          quote do: [pid: var!(pid)]
        else
          quote do: [pid: var!(pid), reference: Finalizer.define(:stop, var!(pid))]
        end))

      { :error, msg } ->
        raise msg
    end
  end

  @doc """
  Returns a random float uniformly distributed between `0.0`
  and `1.0`, updating the state in the process dictionary.
  """
  @spec rand(t) :: float
  def rand(wrap(pid: pid)) do
    :gen_server.call(pid, :rand, :infinity)
  end

  @doc """
  When `max` is an integer, `rand` returns a random integer greater
  than or equal to `0` and less than `max`.
  When `max` is a float, `rand` returns a random floating point
  number between `0.0` and `max`, including `0.0` and excluding
  `max`.
  When `max` is a range, `rand` returns a random number where
  `Enum.member?(range, number) == true`.
  """
  @spec rand(t, integer | float | Range.t) :: integer | float

  def rand(_, max) when is_number(max) and max < 0 do
    0
  end

  def rand(_, 0) do
    0
  end

  def rand(_, 0.0) do
    0.0
  end

  def rand(self, max) when is_float(max) and max > 0 do
    res = rand(self) * max

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

  def rand(wrap(pid: pid), max) when is_integer(max) and max > 0 do
    :gen_server.call(pid, { :rand, max }) - 1
  end

  defp rand(_, min, max) when min == max do
    min
  end

  defp rand(wrap(pid: pid), 1, max) do
    :gen_server.call(pid, { :rand, max })
  end

  defp rand(wrap(pid: pid), min, max) when is_integer(min) do
    min = min - 1
    min + :gen_server.call(pid, { :rand, max - min })
  end

  defp rand(self, min, max) when is_float(min) do
    res = (rand(self) * (max - min)) + min

    if res > max or res < min do
      rand(self, min, max)
    else
      res
    end
  end

  @doc """
  Stop gen_server.
  """
  @spec stop(t) :: :stop
  def stop(wrap(pid: pid)) do
    pid <- :stop
  end
end

defimpl Random.Generator, for: Random.Generator.Standard do
  use Random.Generator.Behaviour

  defdelegate rand(self), to: @for

  defdelegate rand(self, max_or_range), to: @for
end
