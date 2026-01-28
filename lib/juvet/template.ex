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

  ## Templates from files

  Templates can also be loaded from external files using `template_file/2`:

      defmodule MyApp.Templates do
        use Juvet.Template

        template_file :welcome, "templates/welcome.cheex"
      end

  The file path is relative to the module's source file. The module will be
  automatically recompiled when the template file changes.

  ## Introspection

  Modules using `Juvet.Template` get a `__templates__/0` function that returns
  a list of all template names defined in the module:

      MyApp.Templates.__templates__()
      # => [:welcome, :goodbye]
  """

  alias Juvet.Template.{Compiler, Parser, Renderer, Tokenizer}

  defdelegate render(template), to: Renderer
  defdelegate render(template, assigns), to: Renderer

  @doc """
  Sets up compile-time template support.

  Imports the `template/2` and `template_file/2` macros for defining compiled templates.
  Also generates a `__templates__/0` function that returns a list of defined template names.
  """
  defmacro __using__(_opts) do
    quote do
      import Juvet.Template, only: [template: 2, template_file: 2]
      Module.register_attribute(__MODULE__, :juvet_templates, accumulate: true)
      Module.register_attribute(__MODULE__, :juvet_template_asts, accumulate: true)
      @before_compile Juvet.Template
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    templates = Module.get_attribute(env.module, :juvet_templates) |> Enum.reverse()
    template_asts = Module.get_attribute(env.module, :juvet_template_asts) |> Enum.reverse()

    ast_clauses =
      for {name, ast} <- template_asts do
        quote do
          def __template_ast__(unquote(name)), do: unquote(Macro.escape(ast))
        end
      end

    quote do
      @doc """
      Returns a list of template names defined in this module.
      """
      def __templates__, do: unquote(templates)

      @doc """
      Returns the AST for a template by name.

      Used internally for partial resolution at compile time.
      """
      unquote_splicing(ast_clauses)

      def __template_ast__(name) do
        raise ArgumentError, "template #{inspect(name)} not found in #{inspect(__MODULE__)}"
      end
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
    {ast, json} = compile_template!(name, source)

    quote do
      @juvet_templates unquote(name)
      @juvet_template_asts {unquote(name), unquote(Macro.escape(ast))}
      unquote(generate_template_function(name, json))
    end
  end

  @doc """
  Defines a compiled template function from an external file.

  The file is read and compiled at compile time. The module will be
  recompiled when the template file changes.

  ## Example

      template_file :welcome, "templates/welcome.cheex"

  The path is relative to the file containing the module.
  """
  defmacro template_file(name, path) do
    caller_dir = Path.dirname(__CALLER__.file)
    full_path = Path.expand(path, caller_dir)

    source =
      case File.read(full_path) do
        {:ok, content} ->
          content

        {:error, reason} ->
          raise CompileError,
            description:
              "template_file #{inspect(name)} could not read #{path}: #{inspect(reason)}"
      end

    {ast, json} = compile_template!(name, source)

    quote do
      @juvet_templates unquote(name)
      @juvet_template_asts {unquote(name), unquote(Macro.escape(ast))}
      @external_resource unquote(full_path)
      unquote(generate_template_function(name, json))
    end
  end

  @doc """
  Compiles template source to AST and JSON, raising on errors.

  Runs the template through the tokenizer, parser, and compiler pipeline.
  Returns `{ast, json}` tuple where:
  - `ast` is the parsed AST (list of element maps)
  - `json` is the compiled JSON string

  Errors are caught and re-raised as `CompileError` with helpful context.

  This is an internal function used by the `template/2` and `template_file/2`
  macros at compile time.
  """
  def compile_template!(name, source) do
    ast =
      source
      |> Tokenizer.tokenize()
      |> Parser.parse()

    json = Compiler.compile(ast)
    {ast, json}
  rescue
    e in Juvet.Template.TokenizerError ->
      reraise CompileError,
              [
                description:
                  "template #{inspect(name)} has a syntax error: #{Exception.message(e)}",
                line: e.line
              ],
              __STACKTRACE__

    e in Juvet.Template.ParserError ->
      reraise CompileError,
              [
                description:
                  "template #{inspect(name)} has a parse error: #{Exception.message(e)}",
                line: e.line
              ],
              __STACKTRACE__

    e in ArgumentError ->
      reraise CompileError,
              [description: "template #{inspect(name)} failed to compile: #{e.message}"],
              __STACKTRACE__
  end

  # Generates the quoted function definition for a template.
  #
  # If the compiled JSON contains EEx interpolation markers (`<%`),
  # generates a function that calls `EEx.eval_string/2` at runtime.
  # Otherwise, generates a function that returns the static JSON directly.
  defp generate_template_function(name, json) do
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
