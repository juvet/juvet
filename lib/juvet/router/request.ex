defmodule Juvet.Router.Request do
  @moduledoc """
  Represents a single request from a platform.
  """

  alias Juvet.Router.RequestParamDecoder

  @type t :: %__MODULE__{
          host: String.t(),
          method: String.t(),
          params: map(),
          path: String.t(),
          port: integer(),
          private: map(),
          query_string: String.t(),
          raw_params: map(),
          scheme: atom(),
          status: atom(),
          headers: list({String.t(), String.t()}),
          platform: atom(),
          verified?: boolean()
        }
  defstruct [
    :host,
    :method,
    :params,
    :path,
    :port,
    :private,
    :query_string,
    :raw_params,
    :scheme,
    :status,
    headers: [],
    platform: :unknown,
    verified?: false
  ]

  @spec new(Plug.Conn.t()) :: Juvet.Router.Request.t()
  def new(conn) do
    %__MODULE__{
      headers: Map.get(conn, :req_headers),
      host: Map.get(conn, :host),
      method: Map.get(conn, :method),
      raw_params: Map.get(conn, :params),
      path: Map.get(conn, :request_path),
      port: Map.get(conn, :port),
      private: Map.get(conn, :private),
      query_string: Map.get(conn, :query_string),
      scheme: Map.get(conn, :scheme),
      status: Map.get(conn, :status),
      params: %{}
    }
  end

  @spec base_url(Juvet.Router.Request.t()) :: String.t()
  def base_url(%__MODULE{host: host, port: port, scheme: scheme}) do
    IO.iodata_to_binary([
      to_string(scheme),
      "://",
      host,
      base_url_port(scheme, port)
    ])
  end

  def decode_raw_params(%__MODULE__{} = request), do: RequestParamDecoder.decode(request)

  @spec get_header(Juvet.Router.Request.t(), String.t()) :: list(String.t())
  def get_header(%__MODULE__{headers: nil}, _header), do: []

  def get_header(%__MODULE__{headers: headers}, header) do
    for {^header, value} <- headers, do: value
  end

  defp base_url_port(:http, 80), do: ""
  defp base_url_port(:https, 443), do: ""
  defp base_url_port(_, port), do: [?:, Integer.to_string(port)]
end
