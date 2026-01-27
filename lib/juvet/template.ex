defmodule Juvet.Template do
  @moduledoc """
  Compile-time template compilation for Juvet templates.

  Templates are compiled to JSON at compile time, with only EEx interpolation
  happening at runtime.

  ## Usage

      defmodule MyApp.Templates do
        use Juvet.Template

        template :welcome, \"\"\"
        :slack.header{text: "Hello <%= name %>"}
        :slack.divider
        \"\"\"
      end

      MyApp.Templates.welcome(name: "World")
      # => {"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello World"}},{"type":"divider"}]}

  """

  alias Juvet.Template.{Compiler, Parser, Renderer, Tokenizer}

  defdelegate render(template), to: Renderer
  defdelegate render(template, assigns), to: Renderer

  @doc """
  Sets up compile-time template support.

  Imports the `template/2` macro for defining compiled templates.
  """
  defmacro __using__(_opts) do
    quote do
      import Juvet.Template, only: [template: 2]
    end
  end

  @doc """
  Defines a compiled template function.

  The template source is compiled to JSON at compile time. At runtime,
  only EEx interpolation is performed. If the template has no interpolations,
  the compiled JSON is returned directly without EEx evaluation.

  ## Example

      template :greeting, ":slack.header{text: \\"Hello <%= name %>\\"}"

  Generates a function `greeting/1` that accepts a keyword list of bindings.
  """
  defmacro template(name, source) do
    json =
      source
      |> Tokenizer.tokenize()
      |> Parser.parse()
      |> Compiler.compile()

    if String.contains?(json, "<%") do
      quote do
        def unquote(name)(bindings \\ []) do
          EEx.eval_string(unquote(json), bindings)
        end
      end
    else
      quote do
        def unquote(name)(_bindings \\ []), do: unquote(json)
      end
    end
  end
end
