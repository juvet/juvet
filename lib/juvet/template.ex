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

  Templates can also be loaded from external files using the `file:` option:

      defmodule MyApp.Templates do
        use Juvet.Template

        template :welcome, file: "templates/welcome.cheex"
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

  Imports the `template/2` and `partial/2` macros for defining compiled templates
  and partials.
  Also generates a `__templates__/0` function that returns a list of defined template names.
  """
  defmacro __using__(_opts) do
    quote do
      import Juvet.Template, only: [template: 2, partial: 2]
      Module.register_attribute(__MODULE__, :juvet_templates, accumulate: true)
      Module.register_attribute(__MODULE__, :juvet_template_asts, [])
      @before_compile Juvet.Template
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    templates = Module.get_attribute(env.module, :juvet_templates) |> Enum.reverse()
    template_asts = Module.get_attribute(env.module, :juvet_template_asts) || %{}

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

  ## Inline template

      template :greeting, ":slack.header{text: \\"Hello <%= name %>\\"}"

  ## File-based template

      template :greeting, file: "templates/greeting.cheex"

  The file path is relative to the file containing the module. The module
  will be recompiled when the template file changes.

  Generates a function `greeting/1` that accepts a keyword list of bindings.
  """
  defmacro template(name, source) when is_binary(source) do
    existing_asts = Module.get_attribute(__CALLER__.module, :juvet_template_asts) || %{}
    {ast, json} = compile_template!(name, source, existing_asts)

    Module.put_attribute(
      __CALLER__.module,
      :juvet_template_asts,
      Map.put(existing_asts, name, ast)
    )

    quote do
      @juvet_templates unquote(name)
      unquote(generate_template_function(name, json))
    end
  end

  defmacro template(name, opts) when is_list(opts) do
    path = Keyword.fetch!(opts, :file)
    caller_dir = Path.dirname(__CALLER__.file)
    full_path = Path.expand(path, caller_dir)

    source =
      case File.read(full_path) do
        {:ok, content} ->
          content

        {:error, reason} ->
          raise CompileError,
            description: "template #{inspect(name)} could not read #{path}: #{inspect(reason)}"
      end

    existing_asts = Module.get_attribute(__CALLER__.module, :juvet_template_asts) || %{}
    {ast, json} = compile_template!(name, source, existing_asts)

    Module.put_attribute(
      __CALLER__.module,
      :juvet_template_asts,
      Map.put(existing_asts, name, ast)
    )

    quote do
      @juvet_templates unquote(name)
      @external_resource unquote(full_path)
      unquote(generate_template_function(name, json))
    end
  end

  @doc """
  Defines a partial template for inlining into other templates.

  Partials are block-level fragments — they store AST for reference by other
  templates but don't compile to standalone JSON or generate callable functions.

  ## Inline partial

      partial :user_header, ":slack.header{text: \\"Hello <%= name %>\\"}"

  ## File-based partial

      partial :user_header, file: "templates/user_header.cheex"

  The file path is relative to the module's source file.
  """
  defmacro partial(name, source) when is_binary(source) do
    store_partial(name, source, __CALLER__)
  end

  defmacro partial(name, opts) when is_list(opts) do
    path = Keyword.fetch!(opts, :file)
    caller_dir = Path.dirname(__CALLER__.file)
    full_path = Path.expand(path, caller_dir)

    source =
      case File.read(full_path) do
        {:ok, content} ->
          content

        {:error, reason} ->
          raise CompileError,
            description: "partial #{inspect(name)} could not read #{path}: #{inspect(reason)}"
      end

    store_partial(name, source, __CALLER__)

    quote do
      @external_resource unquote(full_path)
    end
  end

  @doc false
  def store_partial(name, source, caller) do
    existing_asts = Module.get_attribute(caller.module, :juvet_template_asts) || %{}

    ast =
      source
      |> Tokenizer.tokenize()
      |> Parser.parse()

    Module.put_attribute(
      caller.module,
      :juvet_template_asts,
      Map.put(existing_asts, name, ast)
    )
  rescue
    e in Tokenizer.Error ->
      reraise CompileError,
              [
                description:
                  "partial #{inspect(name)} has a syntax error: #{Exception.message(e)}",
                line: e.line
              ],
              __STACKTRACE__

    e in Parser.Error ->
      reraise CompileError,
              [
                description:
                  "partial #{inspect(name)} has a parse error: #{Exception.message(e)}",
                line: e.line
              ],
              __STACKTRACE__
  end

  @doc """
  Compiles template source to AST and JSON, raising on errors.

  Runs the template through the tokenizer, parser, and compiler pipeline.
  Resolves any `:partial` elements by inlining referenced template ASTs.

  Returns `{ast, json}` tuple where:
  - `ast` is the parsed AST (before partial resolution)
  - `json` is the compiled JSON string (with partials resolved)

  Errors are caught and re-raised as `CompileError` with helpful context.

  This is an internal function used by the `template/2` macro at compile time.
  """
  def compile_template!(name, source, existing_asts \\ []) do
    ast =
      source
      |> Tokenizer.tokenize()
      |> Parser.parse()

    resolved_ast = resolve_partials(ast, existing_asts)
    json = Compiler.compile(resolved_ast)
    {ast, json}
  rescue
    e in Juvet.Template.Tokenizer.Error ->
      reraise CompileError,
              [
                description:
                  "template #{inspect(name)} has a syntax error: #{Exception.message(e)}",
                line: e.line
              ],
              __STACKTRACE__

    e in Juvet.Template.Parser.Error ->
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

  # Resolves :partial elements in the AST by inlining referenced templates.
  #
  # For each :partial element found:
  # 1. Look up the referenced template's AST from existing_asts
  # 2. Substitute bindings from the partial's attributes into the referenced AST
  # 3. Replace the :partial element with the inlined blocks
  defp resolve_partials(ast, existing_asts) do
    resolve_partials(ast, existing_asts, [])
  end

  defp resolve_partials(ast, existing_asts, stack) do
    Enum.flat_map(ast, fn element ->
      case element do
        %{element: :partial} ->
          resolve_partial(element, existing_asts, stack)

        %{children: children} = el when is_map(children) ->
          [%{el | children: resolve_partials_in_children(children, existing_asts, stack)}]

        other ->
          [other]
      end
    end)
  end

  defp resolve_partials_in_children(children, existing_asts, stack) do
    Map.new(children, fn
      {key, elements} when is_list(elements) ->
        {key, resolve_partials(elements, existing_asts, stack)}

      {key, %{element: :partial} = element} ->
        {key, resolve_partial(element, existing_asts, stack)}

      {key, %{children: nested} = element} when is_map(nested) ->
        {key, %{element | children: resolve_partials_in_children(nested, existing_asts, stack)}}

      {key, value} ->
        {key, value}
    end)
  end

  defp resolve_partial(element, existing_asts, stack) do
    attrs = element.attributes
    location = format_location(element)

    template_name =
      case Map.fetch(attrs, :template) do
        {:ok, name} ->
          name

        :error ->
          raise ArgumentError,
                "partial is missing required template: attribute#{location}"
      end

    bindings = Map.drop(attrs, [:template])

    if template_name in stack do
      cycle = stack |> Enum.reverse() |> Enum.concat([template_name]) |> Enum.join(" -> ")

      raise ArgumentError,
            "circular partial reference detected: #{cycle}#{location}"
    end

    case Map.fetch(existing_asts, template_name) do
      {:ok, partial_ast} ->
        inlined = substitute_bindings(partial_ast, bindings)
        resolve_partials(inlined, existing_asts, [template_name | stack])

      :error ->
        raise ArgumentError,
              "partial #{inspect(template_name)} not found#{location}"
    end
  end

  defp format_location(%{line: line, column: col}) when is_integer(line) and is_integer(col) do
    " (line #{line}, column #{col})"
  end

  defp format_location(%{line: line}) when is_integer(line) do
    " (line #{line})"
  end

  defp format_location(_), do: ""

  # Substitutes bindings into an AST.
  #
  # For each EEx interpolation `<%= name %>` in the partial's AST,
  # replaces it with the corresponding binding value.
  #
  # Example:
  #   partial AST has: %{text: "Hello <%= name %>"}
  #   bindings: %{name: "<%= user_name %>"}
  #   result: %{text: "Hello <%= user_name %>"}
  defp substitute_bindings(ast, bindings) when is_list(ast) do
    Enum.map(ast, &substitute_bindings(&1, bindings))
  end

  defp substitute_bindings(%{} = element, bindings) do
    element
    |> Map.update(:attributes, %{}, &substitute_in_attributes(&1, bindings))
    |> Map.update(:children, nil, &substitute_in_children(&1, bindings))
    |> then(fn el ->
      if el.children == nil, do: Map.delete(el, :children), else: el
    end)
  end

  defp substitute_in_attributes(attrs, bindings) do
    Map.new(attrs, fn {key, value} ->
      {key, substitute_in_value(value, bindings)}
    end)
  end

  defp substitute_in_value(value, bindings) when is_binary(value) do
    Enum.reduce(bindings, value, fn {name, replacement}, acc ->
      String.replace(acc, "<%= #{name} %>", to_string(replacement))
    end)
  end

  defp substitute_in_value(value, _bindings), do: value

  defp substitute_in_children(nil, _bindings), do: nil

  defp substitute_in_children(children, bindings) when is_map(children) do
    Map.new(children, fn {key, value} ->
      {key, substitute_in_child_value(value, bindings)}
    end)
  end

  defp substitute_in_child_value(value, bindings) when is_list(value) do
    Enum.map(value, &substitute_bindings(&1, bindings))
  end

  defp substitute_in_child_value(value, bindings) when is_map(value) do
    substitute_bindings(value, bindings)
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
