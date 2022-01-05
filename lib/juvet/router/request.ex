defmodule Juvet.Router.Request do
  defstruct headers: [],
            host: nil,
            method: nil,
            params: nil,
            path: nil,
            port: nil,
            query_string: nil,
            scheme: nil,
            status: nil

  def new(conn) do
    %__MODULE__{
      headers: conn.req_headers,
      host: conn.host,
      method: conn.method,
      params: conn.params,
      path: conn.request_path,
      port: conn.port,
      query_string: conn.query_string,
      scheme: conn.scheme,
      status: conn.status
    }
  end

  def get_header(%__MODULE__{headers: headers}, header) do
    for {^header, value} <- headers, do: value
  end
end