defmodule HelloWorld do
  @moduledoc """
  A simple Hello World application for Anoma.
  """

  @doc """
  Greets a person with a customized message.

  ## Examples

      iex> HelloWorld.greet("Alice")
      "Hello Alice, welcome to Anoma!"

  """
  def greet(name) do
    "Hello #{name}, welcome to Anoma!"
  end

  @doc """
  Returns a simple greeting.

  ## Examples

      iex> HelloWorld.hello()
      "Hello, Anoma World!"

  """
  def hello do
    "Hello, Anoma World!"
  end
end

