defmodule Juvet.Template.Compiler do
  @moduledoc """
  Compiles an AST into JSON for the target platform.

  Delegates to platform-specific compilers based on the `platform:` field
  in each AST element.

  ## Example

      iex> ast = [%{platform: :slack, element: :divider, attributes: %{}}]
      iex> Juvet.Template.Compiler.compile(ast)
      ~s({"blocks":[{"type":"divider"}]})

  See `docs/templates.md` for the full pipeline documentation.
  """

  alias Juvet.Template.Compiler.Slack

  @type ast_element :: %{
          :platform => atom(),
          :element => atom(),
          :attributes => map(),
          optional(:children) => map()
        }

  @spec compile([ast_element()]) :: String.t()
  def compile([]), do: ""
  def compile([%{platform: :slack} | _] = ast), do: Slack.compile(ast)
end
