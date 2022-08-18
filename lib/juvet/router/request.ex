defmodule Juvet.Router.Request do
  @moduledoc """
  Represents a single request from a platform.
  """

  @type t :: %__MODULE__{}
  defstruct [
    :host,
    :method,
    :params,
    :path,
    :port,
    :private,
    :query_string,
    :scheme,
    :status,
    headers: [],
    platform: :unknown,
    verified?: false
  ]

  def new(conn) do
    %__MODULE__{
      headers: Map.get(conn, :req_headers),
      host: Map.get(conn, :host),
      method: Map.get(conn, :method),
      params: Map.get(conn, :params),
      path: Map.get(conn, :request_path),
      port: Map.get(conn, :port),
      private: Map.get(conn, :private),
      query_string: Map.get(conn, :query_string),
      scheme: Map.get(conn, :scheme),
      status: Map.get(conn, :status)
    }
  end

  def get_header(%__MODULE__{headers: nil}, _header), do: []

  def get_header(%__MODULE__{headers: headers}, header) do
    for {^header, value} <- headers, do: value
  end
end
