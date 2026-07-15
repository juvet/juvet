defmodule Juvet.Template.Compiler do
  @moduledoc """
  Compiles an AST into JSON for the target platform.

  Delegates to platform-specific compilers based on the `platform:` field
  in each AST element.

  ## Example

      iex> ast = [%{platform: :slack, element: :view, attributes: %{type: :modal}, children: %{blocks: [%{platform: :slack, element: :divider, attributes: %{}}]}}]
      iex> Juvet.Template.Compiler.compile(ast)
      ~s({"blocks":[{"type":"divider"}],"type":"modal"})

  See `docs/templates.md` for the full pipeline documentation.
  """

  alias Juvet.Template.Compiler.Slack

  # `:attributes` is optional: top-level `blocks:` nodes (blocks-only message
  # templates) are built without one.
  @type ast_element :: %{
          :platform => atom(),
          :element => atom(),
          optional(:attributes) => map(),
          optional(:children) => map(),
          optional(:line) => pos_integer(),
          optional(:column) => pos_integer()
        }

  # A `.view` template compiles to a view map; a blocks-only template
  # compiles to a bare list of blocks.
  @spec compile([ast_element()]) :: map() | [map()]
  def compile([]), do: %{}
  def compile([%{platform: :slack} | _] = ast), do: Slack.compile(ast)
end
