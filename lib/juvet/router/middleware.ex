defmodule Juvet.Router.Middleware do
  @moduledoc """
  Represents a piece of middleware that can be run within a `Middleware.Processor`.
  """

  @type t :: %__MODULE__{
          module: module(),
          platform: atom() | nil,
          partial: boolean()
        }
  @enforce_keys [:module]
  defstruct [:module, partial: false, platform: nil]

  @spec new(module(), keyword()) :: Juvet.Router.Middleware.t()
  def new(module, opts \\ []) do
    partial = Keyword.get(opts, :partial, defaults().partial)
    platform = Keyword.get(opts, :platform, defaults().platform)

    %__MODULE__{module: module, partial: partial, platform: platform}
  end

  @spec put_middleware(list(Juvet.Router.Middleware.t()), Juvet.Router.Middleware.t()) ::
          list(Juvet.Router.Middleware.t())
  def put_middleware(middlewares, middleware) do
    middlewares
    |> Enum.find_index(fn %{module: module} -> module == Juvet.Middleware.ActionGenerator end)
    |> case do
      nil ->
        raise ArgumentError, message: "Middleware incorrectly compiled."

      index ->
        List.insert_at(middlewares, index, middleware)
    end
  end

  @spec system() :: list(Juvet.Router.Middleware.t())
  def system do
    [
      new(Juvet.Middleware.ParseRequest),
      new(Juvet.Middleware.IdentifyRequest),
      new(Juvet.Middleware.Slack.VerifyRequest),
      new(Juvet.Middleware.DecodeRequestParams),
      new(Juvet.Middleware.NormalizeRequestParams),
      new(Juvet.Middleware.BuildDefaultResponse),
      new(Juvet.Middleware.RouteRequest),
      new(Juvet.Middleware.ActionGenerator, partial: true),
      new(Juvet.Middleware.ActionRunner, partial: true)
    ]
  end

  defp defaults, do: __MODULE__.__struct__()
end
