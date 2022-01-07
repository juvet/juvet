defmodule Juvet.Router.Request do
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
    headers: []
  ]

  def new(conn) do
    %__MODULE__{
      headers: conn.req_headers,
      host: conn.host,
      method: conn.method,
      params: conn.params,
      path: conn.request_path,
      port: conn.port,
      private: conn.private,
      query_string: conn.query_string,
      scheme: conn.scheme,
      status: conn.status
    }
  end

  def get_header(%__MODULE__{headers: headers}, header) do
    for {^header, value} <- headers, do: value
  end
end
