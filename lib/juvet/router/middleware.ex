defmodule Juvet.Router.Middleware do
  @moduledoc """
  Represents a piece of middleware that can be run within a `Middleware.Processor`.
  """

  @type t :: %__MODULE__{
          module: module(),
          platform: atom() | nil,
          partial: boolean() | nil
        }
  @enforce_keys [:module]
  defstruct [:module, partial: nil, platform: nil]

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
      new(Juvet.Middleware.ParseRequest, partial: false),
      new(Juvet.Middleware.IdentifyRequest, partial: false),
      new(Juvet.Middleware.Slack.VerifyRequest, partial: false),
      new(Juvet.Middleware.DecodeRequestParams, partial: false),
      new(Juvet.Middleware.NormalizeRequestParams, partial: false),
      new(Juvet.Middleware.RouteRequest, partial: false),
      new(Juvet.Middleware.BuildDefaultResponse, partial: false),
      new(Juvet.Middleware.ActionGenerator),
      new(Juvet.Middleware.ActionRunner)
    ]
  end

  defp defaults, do: __MODULE__.__struct__()
end
