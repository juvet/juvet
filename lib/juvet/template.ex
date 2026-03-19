defmodule Juvet.Template do
  @moduledoc """
  Compile-time template compilation for Juvet templates.

  Templates are compiled at compile time, with only EEx interpolation
  happening at runtime. By default, template functions return atom-keyed maps.

  ## Usage

      defmodule MyApp.Templates do
        use Juvet.Template

        template :welcome, \"\"\"
        :slack.header{text: "Hello <%= name %>"}
        :slack.divider
        \"\"\"
      end

      MyApp.Templates.welcome(name: "World")
      #=> %{type: "modal", blocks: [%{type: "header", text: %{type: "plain_text", text: "Hello World"}}, ...]}

  ## Format option

  The `format` option controls the return type. Default is `:map`.

      # Module-level default
      use Juvet.Template, format: :json

      # Per-template override
      template :greeting, ":slack.view ...", format: :json

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

  Imports the `template/2`, `template/3`, and `partial/2` macros for defining
  compiled templates and partials.

  ## Options

    * `:format` - The default output format for templates in this module.
      `:map` (default) returns atom-keyed maps, `:json` returns JSON strings.

  Also generates a `__templates__/0` function that returns a list of defined template names.
  """
  defmacro __using__(opts) do
    format = Keyword.get(opts, :format, :map)

    helpers =
      opts
      |> Keyword.get(:helpers, [])
      |> Enum.map(&Macro.expand(&1, __CALLER__))

    Module.put_attribute(__CALLER__.module, :juvet_template_format, format)
    Module.put_attribute(__CALLER__.module, :juvet_template_helpers, helpers)

    quote do
      import Juvet.Template, only: [template: 2, template: 3, partial: 2]
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

  The template source is compiled at compile time. At runtime,
  only EEx interpolation is performed. By default, returns an atom-keyed map.

  ## Inline template

      template :greeting, ":slack.header{text: \\"Hello <%= name %>\\"}"

  ## File-based template

      template :greeting, file: "templates/greeting.cheex"

  ## With format override

      template :greeting, ":slack.header{text: \\"Hello\\"}", format: :json

  The file path is relative to the file containing the module. The module
  will be recompiled when the template file changes.

  Generates a function `greeting/1` that accepts a keyword list of bindings.
  """
  defmacro template(name, source) when is_binary(source) do
    format = Module.get_attribute(__CALLER__.module, :juvet_template_format) || :map
    do_compile_template(name, source, format, __CALLER__)
  end

  defmacro template(name, opts) when is_list(opts) do
    format =
      Keyword.get(
        opts,
        :format,
        Module.get_attribute(__CALLER__.module, :juvet_template_format) || :map
      )

    if file_option_specified?(opts) do
      do_file_template(name, opts, format, __CALLER__)
    else
      {source, compile_opts} = extract_inline_source(opts)
      do_compile_template(name, source, format, __CALLER__, compile_opts)
    end
  end

  @doc """
  Defines a compiled template function with options.

  Accepts inline source and a keyword list of options.

  ## Options

    * `:format` - Override the module-level format for this template.
      `:map` returns atom-keyed maps, `:json` returns JSON strings.

  ## Example

      template :greeting, ":slack.view ...", format: :json
  """
  defmacro template(name, source, opts) when is_binary(source) and is_list(opts) do
    format =
      Keyword.get(
        opts,
        :format,
        Module.get_attribute(__CALLER__.module, :juvet_template_format) || :map
      )

    do_compile_template(name, source, format, __CALLER__)
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
    if file_option_specified?(opts) do
      do_file_partial(name, opts, __CALLER__)
    else
      {source, compile_opts} = extract_inline_source(opts)
      store_partial(name, source, __CALLER__, compile_opts)
    end
  end

  @doc """
  Compiles template source to AST and compiled map, raising on errors.

  Runs the template through the tokenizer, parser, and compiler pipeline.
  Resolves any `:partial` elements by inlining referenced template ASTs.

  Returns `{ast, compiled_map}` tuple where:
  - `ast` is the parsed AST (before partial resolution)
  - `compiled_map` is the compiled atom-keyed map (with partials resolved)

  Errors are caught and re-raised as `CompileError` with helpful context.

  This is an internal function used by the `template/2` macro at compile time.
  """
  def compile_template!(name, source, existing_asts \\ [], opts \\ []) do
    platform = Keyword.get(opts, :platform)
    tokens = Tokenizer.tokenize(source)

    ast =
      if platform do
        Parser.parse(tokens, platform: platform)
      else
        Parser.parse(tokens)
      end

    if platform, do: validate_platform!(ast, platform)

    resolved_ast = resolve_partials(ast, existing_asts)
    compiled = Compiler.compile(resolved_ast)
    {ast, compiled}
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

        %{node_type: :for_loop} = node ->
          [%{node | body: resolve_partials(node.body, existing_asts, stack)}]

        %{node_type: :code_block} = node ->
          [node]

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

  defp store_partial(name, source, caller, opts \\ []) do
    existing_asts = Module.get_attribute(caller.module, :juvet_template_asts) || %{}
    platform = Keyword.get(opts, :platform)

    tokens = Tokenizer.tokenize(source)

    ast =
      if platform do
        Parser.parse(tokens, platform: platform)
      else
        Parser.parse(tokens)
      end

    if platform, do: validate_platform!(ast, platform)

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

    e in ArgumentError ->
      reraise CompileError,
              [description: "partial #{inspect(name)} failed to compile: #{e.message}"],
              __STACKTRACE__
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

  defp substitute_bindings(%{node_type: :for_loop} = node, bindings) do
    %{node | body: substitute_bindings(node.body, bindings)}
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

  @doc """
  Executes a list of callbacks with binding threading via map_reduce.

  Each callback receives the current bindings and returns `{result, new_bindings}`.
  Code block callbacks return `{nil, updated_bindings}` and regular element
  callbacks return `{element, same_bindings}`. Nils are filtered from the result.
  """
  def execute_with_binding_threading(callbacks, bindings) do
    {elements, final_bindings} =
      Enum.map_reduce(callbacks, bindings, fn callback, acc_bindings ->
        callback.(acc_bindings)
      end)

    {elements |> List.flatten() |> Enum.reject(&is_nil/1), final_bindings}
  end

  @doc """
  Evaluates EEx interpolations within a nested map/list structure at runtime.

  Walks the data structure and evaluates any string values containing EEx
  markers (`<%`) using the provided bindings. Non-string values are returned
  as-is.
  """
  def eval_map(data, bindings) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, eval_map(v, bindings)} end)
  end

  def eval_map(data, bindings) when is_list(data) do
    Enum.map(data, &eval_map(&1, bindings))
  end

  def eval_map(data, bindings) when is_binary(data) do
    if String.contains?(data, "<%") do
      EEx.eval_string(data, bindings)
    else
      data
    end
  end

  def eval_map(data, _bindings), do: data

  # Extracts the source string from an opts keyword list for inline templates.
  # Returns {source, remaining_opts} where remaining_opts may include :platform.
  @platform_keys [:slack]

  defp extract_inline_source(opts) do
    cond do
      inline_option_specified?(opts) ->
        source = Keyword.fetch!(opts, :inline)
        {source, Keyword.delete(opts, :inline)}

      platform_key = platform_option(opts) ->
        source = Keyword.fetch!(opts, platform_key)
        rest = Keyword.delete(opts, platform_key)
        {source, Keyword.put(rest, :platform, platform_key)}

      true ->
        raise ArgumentError,
              "expected :file, :inline, or a platform key (e.g., :slack)"
    end
  end

  # Handles file-based template compilation.
  defp do_file_template(name, opts, format, caller) do
    path = Keyword.fetch!(opts, :file)
    caller_dir = Path.dirname(caller.file)
    full_path = Path.expand(path, caller_dir)

    source =
      case File.read(full_path) do
        {:ok, content} ->
          content

        {:error, reason} ->
          raise CompileError,
            description: "template #{inspect(name)} could not read #{path}: #{inspect(reason)}"
      end

    platform = extract_platform_from_filename(path)

    existing_asts = Module.get_attribute(caller.module, :juvet_template_asts) || %{}
    helpers = Module.get_attribute(caller.module, :juvet_template_helpers) || []
    {ast, compiled} = compile_template!(name, source, existing_asts, platform: platform)

    Module.put_attribute(
      caller.module,
      :juvet_template_asts,
      Map.put(existing_asts, name, ast)
    )

    helper_bindings = build_helper_bindings(helpers)

    quote do
      @juvet_templates unquote(name)
      @external_resource unquote(full_path)
      unquote(generate_template_function(name, compiled, format, helper_bindings))
    end
  end

  # Handles file-based partial compilation.
  defp do_file_partial(name, opts, caller) do
    path = Keyword.fetch!(opts, :file)
    caller_dir = Path.dirname(caller.file)
    full_path = Path.expand(path, caller_dir)

    source =
      case File.read(full_path) do
        {:ok, content} ->
          content

        {:error, reason} ->
          raise CompileError,
            description: "partial #{inspect(name)} could not read #{path}: #{inspect(reason)}"
      end

    platform = extract_platform_from_filename(path)
    store_partial(name, source, caller, platform: platform)

    quote do
      @external_resource unquote(full_path)
    end
  end

  # Shared implementation for compiling inline template source.
  defp do_compile_template(name, source, format, caller, opts \\ []) do
    existing_asts = Module.get_attribute(caller.module, :juvet_template_asts) || %{}
    helpers = Module.get_attribute(caller.module, :juvet_template_helpers) || []
    {ast, compiled} = compile_template!(name, source, existing_asts, opts)

    Module.put_attribute(
      caller.module,
      :juvet_template_asts,
      Map.put(existing_asts, name, ast)
    )

    helper_bindings = build_helper_bindings(helpers)

    quote do
      @juvet_templates unquote(name)
      unquote(generate_template_function(name, compiled, format, helper_bindings))
    end
  end

  # Generates the quoted function definition for a template.
  defp generate_template_function(name, compiled, :json, helper_bindings),
    do: generate_json_function(name, compiled, helper_bindings)

  defp generate_template_function(name, compiled, :map, helper_bindings),
    do: generate_map_function(name, compiled, helper_bindings)

  defp generate_json_function(name, compiled, helper_bindings) when is_map(compiled) do
    cond do
      map_contains_for?(compiled) or map_contains_code_block?(compiled) ->
        bindings_var = Macro.var(:bindings, __MODULE__)
        body = compiled_to_quoted(compiled, bindings_var)

        quote do
          def unquote(name)(bindings \\ []) do
            unquote(bindings_var) = Keyword.merge(unquote(helper_bindings), bindings)
            Juvet.Template.Compiler.Encoder.encode!(unquote(body))
          end
        end

      map_contains_eex?(compiled) ->
        json = Compiler.Encoder.encode!(compiled)

        quote do
          def unquote(name)(bindings \\ []) do
            merged = Keyword.merge(unquote(helper_bindings), bindings)
            EEx.eval_string(unquote(json), merged)
          end
        end

      true ->
        json = Compiler.Encoder.encode!(compiled)

        quote do
          def unquote(name)(_bindings \\ []), do: unquote(json)
        end
    end
  end

  defp generate_map_function(name, compiled, helper_bindings) when is_map(compiled) do
    cond do
      map_contains_for?(compiled) or map_contains_code_block?(compiled) ->
        bindings_var = Macro.var(:bindings, __MODULE__)
        body = compiled_to_quoted(compiled, bindings_var)

        quote do
          def unquote(name)(bindings \\ []) do
            unquote(bindings_var) = Keyword.merge(unquote(helper_bindings), bindings)
            unquote(body)
          end
        end

      map_contains_eex?(compiled) ->
        escaped = Macro.escape(compiled)

        quote do
          def unquote(name)(bindings \\ []) do
            merged = Keyword.merge(unquote(helper_bindings), bindings)
            Juvet.Template.eval_map(unquote(escaped), merged)
          end
        end

      true ->
        escaped = Macro.escape(compiled)

        quote do
          def unquote(name)(_bindings \\ []), do: unquote(escaped)
        end
    end
  end

  # Transforms a compiled map/list structure into quoted Elixir AST.
  # Handles __for__ markers by generating real `for` comprehensions.
  # When the for-loop body contains code blocks, uses binding threading.
  defp compiled_to_quoted(%{__for__: true} = node, bindings_var) do
    variable = String.to_atom(node.variable)
    collection = String.to_atom(node.collection)
    item_var = Macro.var(variable, __MODULE__)

    if Enum.any?(node.body, &match?(%{__code_block__: true}, &1)) do
      for_quoted_with_code_blocks(node.body, variable, collection, item_var, bindings_var)
    else
      for_quoted_without_code_blocks(node.body, variable, collection, item_var, bindings_var)
    end
  end

  # Code block marker - generates Code.eval_string with error wrapping
  defp compiled_to_quoted(%{__code_block__: true} = node, bindings_var) do
    code = node.code
    line = Map.get(node, :line)
    column = Map.get(node, :column)

    quote do
      try do
        {_result, new_bindings} = Code.eval_string(unquote(code), unquote(bindings_var))
        {nil, new_bindings}
      rescue
        e ->
          reraise RuntimeError,
                  [
                    message:
                      "Error in code block at line #{unquote(line)}, column #{unquote(column)}: #{Exception.message(e)}"
                  ],
                  __STACKTRACE__
      end
    end
  end

  defp compiled_to_quoted(map, bindings_var) when is_map(map) do
    pairs =
      Enum.map(map, fn {k, v} ->
        {Macro.escape(k), compiled_to_quoted(v, bindings_var)}
      end)

    {:%{}, [], pairs}
  end

  defp compiled_to_quoted(list, bindings_var) when is_list(list) do
    has_code_blocks = Enum.any?(list, &match?(%{__code_block__: true}, &1))
    has_for_loops = Enum.any?(list, &match?(%{__for__: true}, &1))

    cond do
      has_code_blocks ->
        # Use binding threading to thread bindings through the list
        quoted_elements = Enum.map(list, &compiled_to_quoted_with_bindings(&1))

        quote do
          {elements, _final_bindings} =
            Juvet.Template.execute_with_binding_threading(
              unquote(quoted_elements),
              unquote(bindings_var)
            )

          elements
        end

      has_for_loops ->
        segments =
          list
          |> Enum.chunk_by(&match?(%{__for__: true}, &1))
          |> Enum.flat_map(&chunk_to_quoted_segment(&1, bindings_var))

        quote do
          Enum.concat(unquote(segments))
        end

      true ->
        Enum.map(list, &compiled_to_quoted(&1, bindings_var))
    end
  end

  defp compiled_to_quoted(string, bindings_var) when is_binary(string) do
    if String.contains?(string, "<%") do
      quote do
        Juvet.Template.eval_map(unquote(string), unquote(bindings_var))
      end
    else
      Macro.escape(string)
    end
  end

  defp compiled_to_quoted(value, _bindings_var), do: Macro.escape(value)

  # For-loop quoted AST when body contains code blocks - uses binding threading.
  defp for_quoted_with_code_blocks(body, variable, collection, item_var, bindings_var) do
    body_callbacks = Enum.map(body, &compiled_to_quoted_with_bindings/1)

    quote do
      Enum.flat_map(
        Keyword.fetch!(unquote(bindings_var), unquote(collection)),
        fn unquote(item_var) ->
          iter_bindings = Keyword.put(unquote(bindings_var), unquote(variable), unquote(item_var))

          {elements, _} =
            Juvet.Template.execute_with_binding_threading(unquote(body_callbacks), iter_bindings)

          elements
        end
      )
    end
  end

  # For-loop quoted AST when body has no code blocks - simple eval_map approach.
  defp for_quoted_without_code_blocks(body, variable, collection, item_var, bindings_var) do
    body_elements =
      Enum.map(body, fn body_el ->
        escaped_body = Macro.escape(body_el)

        quote do
          Juvet.Template.eval_map(
            unquote(escaped_body),
            Keyword.put(unquote(bindings_var), unquote(variable), unquote(item_var))
          )
        end
      end)

    case body_elements do
      [single] ->
        quote do
          for unquote(item_var) <-
                Keyword.fetch!(unquote(bindings_var), unquote(collection)) do
            unquote(single)
          end
        end

      multiple ->
        quote do
          Enum.flat_map(Keyword.fetch!(unquote(bindings_var), unquote(collection)), fn unquote(
                                                                                         item_var
                                                                                       ) ->
            unquote(multiple)
          end)
        end
    end
  end

  # Generates a quoted callback for Enum.map_reduce binding threading.
  # Code blocks return {nil, updated_bindings}, for-loops return {list, same_bindings},
  # regular elements return {result, same_bindings}.
  defp compiled_to_quoted_with_bindings(%{__code_block__: true} = node) do
    code = node.code
    line = Map.get(node, :line)
    column = Map.get(node, :column)

    quote do
      fn bindings ->
        try do
          {_result, new_bindings} = Code.eval_string(unquote(code), bindings)
          {nil, new_bindings}
        rescue
          e ->
            reraise RuntimeError,
                    [
                      message:
                        "Error in code block at line #{unquote(line)}, column #{unquote(column)}: #{Exception.message(e)}"
                    ],
                    __STACKTRACE__
        end
      end
    end
  end

  defp compiled_to_quoted_with_bindings(%{__for__: true} = node) do
    variable = String.to_atom(node.variable)
    collection = String.to_atom(node.collection)
    item_var = Macro.var(variable, __MODULE__)

    if Enum.any?(node.body, &match?(%{__code_block__: true}, &1)) do
      for_callback_with_code_blocks(node.body, variable, collection, item_var)
    else
      for_callback_without_code_blocks(node.body, variable, collection, item_var)
    end
  end

  defp compiled_to_quoted_with_bindings(element) do
    escaped = Macro.escape(element)

    quote do
      fn bindings ->
        {Juvet.Template.eval_map(unquote(escaped), bindings), bindings}
      end
    end
  end

  defp for_callback_with_code_blocks(body, variable, collection, item_var) do
    body_callbacks = Enum.map(body, &compiled_to_quoted_with_bindings/1)

    quote do
      fn bindings ->
        results =
          Enum.flat_map(
            Keyword.fetch!(bindings, unquote(collection)),
            fn unquote(item_var) ->
              iter_bindings = Keyword.put(bindings, unquote(variable), unquote(item_var))

              {elements, _} =
                Juvet.Template.execute_with_binding_threading(
                  unquote(body_callbacks),
                  iter_bindings
                )

              elements
            end
          )

        {results, bindings}
      end
    end
  end

  defp for_callback_without_code_blocks(body, variable, collection, item_var) do
    body_elements =
      Enum.map(body, fn body_el ->
        escaped_body = Macro.escape(body_el)

        quote do
          Juvet.Template.eval_map(
            unquote(escaped_body),
            Keyword.put(bindings, unquote(variable), unquote(item_var))
          )
        end
      end)

    case body_elements do
      [single] ->
        quote do
          fn bindings ->
            results =
              for unquote(item_var) <- Keyword.fetch!(bindings, unquote(collection)) do
                unquote(single)
              end

            {results, bindings}
          end
        end

      multiple ->
        flat_map_body = for_flat_map_body(collection, item_var, multiple)

        quote do
          fn bindings ->
            {unquote(flat_map_body), bindings}
          end
        end
    end
  end

  defp for_flat_map_body(collection, item_var, body_elements) do
    quote do
      Enum.flat_map(Keyword.fetch!(bindings, unquote(collection)), fn unquote(item_var) ->
        unquote(body_elements)
      end)
    end
  end

  # Converts a chunk of elements (from Enum.chunk_by) into Enum.concat segments.
  # For-loop chunks become individual for comprehensions; static chunks become a literal list.
  defp chunk_to_quoted_segment([%{__for__: true} | _] = chunk, bindings_var) do
    Enum.map(chunk, &compiled_to_quoted(&1, bindings_var))
  end

  defp chunk_to_quoted_segment(static_elements, bindings_var) do
    quoted_elements = Enum.map(static_elements, &compiled_to_quoted(&1, bindings_var))
    [quoted_elements]
  end

  # Builds a quoted keyword list of function captures from helper modules.
  # For each helper module, iterates its exported functions, keeps the highest
  # arity per function name, and raises CompileError on cross-module conflicts.
  defp build_helper_bindings(helpers) do
    all_functions =
      for module <- helpers,
          {name, arity} <- module.__info__(:functions),
          reduce: %{} do
        acc ->
          case Map.get(acc, name) do
            nil ->
              Map.put(acc, name, {module, arity})

            {^module, existing_arity} ->
              Map.put(acc, name, {module, max(arity, existing_arity)})

            {other_module, _} ->
              raise CompileError,
                description:
                  "Helper conflict: #{name} is defined in both #{inspect(module)} and #{inspect(other_module)}"
          end
      end

    captures =
      for {name, {module, arity}} <- all_functions do
        {name, quote(do: &(unquote(module).unquote(name) / unquote(arity)))}
      end

    captures
  end

  defp file_option_specified?(opts), do: Keyword.has_key?(opts, :file)

  # Extracts a platform atom from a filename.
  #
  # "home.slack.cheex" → :slack
  # "greeting.cheex" → nil
  # "my.template.slack.cheex" → :slack
  # "home.discord.cheex" → nil (only :slack recognized)
  defp extract_platform_from_filename(path) do
    recognized = Enum.map(@platform_keys, &Atom.to_string/1)
    parts = path |> Path.basename() |> String.split(".")

    case parts do
      [_ | rest] when length(rest) >= 2 ->
        platform_segment = Enum.at(rest, length(rest) - 2)

        if platform_segment in recognized do
          String.to_atom(platform_segment)
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp inline_option_specified?(opts), do: Keyword.has_key?(opts, :inline)

  defp platform_option(opts),
    do: Enum.find(@platform_keys, &Keyword.has_key?(opts, &1))

  # Validates that all elements in the AST match the expected platform.
  # Raises ArgumentError if a conflicting platform is found.
  defp validate_platform!(ast, expected) when is_list(ast) do
    Enum.each(ast, &validate_platform_element!(&1, expected))
  end

  defp validate_platform_element!(%{node_type: :for_loop} = node, expected) do
    validate_platform!(node.body, expected)
  end

  defp validate_platform_element!(%{node_type: :code_block}, _expected), do: :ok

  defp validate_platform_element!(%{platform: platform, line: line, column: col}, expected)
       when platform != expected do
    raise ArgumentError,
          "platform :#{platform} in template does not match expected platform :#{expected} (line #{line}, column #{col})"
  end

  defp validate_platform_element!(%{children: children} = _element, expected)
       when is_map(children) do
    Enum.each(children, fn
      {_key, child_elements} when is_list(child_elements) ->
        validate_platform!(child_elements, expected)

      {_key, %{} = child} ->
        validate_platform_element!(child, expected)

      _ ->
        :ok
    end)
  end

  defp validate_platform_element!(_element, _expected), do: :ok

  # Checks if a map/list structure contains any EEx interpolation markers.
  defp map_contains_eex?(map) when is_map(map),
    do: Enum.any?(map, fn {_k, v} -> map_contains_eex?(v) end)

  defp map_contains_eex?(list) when is_list(list),
    do: Enum.any?(list, &map_contains_eex?/1)

  defp map_contains_eex?(s) when is_binary(s),
    do: String.contains?(s, "<%")

  defp map_contains_eex?(_), do: false

  # Checks if a compiled structure contains any __code_block__ markers.
  defp map_contains_code_block?(%{__code_block__: true}), do: true

  defp map_contains_code_block?(map) when is_map(map),
    do: Enum.any?(map, fn {_k, v} -> map_contains_code_block?(v) end)

  defp map_contains_code_block?(list) when is_list(list),
    do: Enum.any?(list, &map_contains_code_block?/1)

  defp map_contains_code_block?(_), do: false

  # Checks if a compiled structure contains any __for__ markers.
  defp map_contains_for?(%{__for__: true}), do: true

  defp map_contains_for?(map) when is_map(map),
    do: Enum.any?(map, fn {_k, v} -> map_contains_for?(v) end)

  defp map_contains_for?(list) when is_list(list),
    do: Enum.any?(list, &map_contains_for?/1)

  defp map_contains_for?(_), do: false
end
