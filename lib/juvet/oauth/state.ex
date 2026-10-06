defmodule Juvet.OAuth.State do
  @moduledoc """
  Generates and verifies the OAuth `state` parameter which protects the Slack OAuth
  flow from CSRF and login injection.

  The request phase generates a random state, stores it in a signed, HttpOnly cookie
  scoped to the callback endpoint, and sends it to Slack in the authorize URL. The
  callback phase verifies the `state` Slack sends back matches the cookie.

  The cookie is signed with the `state_secret` from the Slack configuration:

  ```
  config :juvet,
    slack: [
      state_secret: System.fetch_env!("SLACK_STATE_SECRET")
    ]
  ```
  """

  alias Juvet.{Config, ConfigurationError}

  @cookie "_juvet_oauth_state"
  @max_age 600
  @salt "juvet oauth state"

  @doc """
  Returns the name of the cookie which stores the signed state.
  """
  @spec cookie_name() :: String.t()
  def cookie_name, do: @cookie

  @doc """
  Generates a new state and stores it in a signed cookie on the `conn`.

  Returns the `conn` with the cookie and the state to send to the OAuth provider.
  """
  @spec put(Plug.Conn.t(), Keyword.t()) ::
          {:ok, Plug.Conn.t(), String.t()} | {:error, Exception.t()}
  def put(conn, configuration) do
    with {:ok, secret} <- secret(configuration) do
      state = generate()
      token = Plug.Crypto.sign(secret, @salt, state, max_age: @max_age)

      conn =
        Plug.Conn.put_resp_cookie(
          conn,
          @cookie,
          token,
          cookie_options(conn, configuration, max_age: @max_age)
        )

      {:ok, conn, state}
    end
  end

  @doc """
  Verifies the `state` within the `params` matches the state stored in the cookie
  on the `conn`.
  """
  @spec verify(Plug.Conn.t(), map(), Keyword.t()) ::
          :ok | {:error, :invalid_state} | {:error, Exception.t()}
  def verify(conn, params, configuration) do
    with {:ok, secret} <- secret(configuration),
         %{@cookie => token} <- Plug.Conn.fetch_cookies(conn).req_cookies,
         {:ok, state} <- Plug.Crypto.verify(secret, @salt, token, max_age: @max_age),
         %{"state" => param} when is_binary(param) <- params,
         true <- Plug.Crypto.secure_compare(state, param) do
      :ok
    else
      {:error, %ConfigurationError{}} = error -> error
      _ -> {:error, :invalid_state}
    end
  end

  @doc """
  Removes the state cookie so a state can only be used once.
  """
  @spec delete(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def delete(conn, configuration),
    do: Plug.Conn.delete_resp_cookie(conn, @cookie, cookie_options(conn, configuration))

  defp cookie_options(conn, configuration, options \\ []) do
    Keyword.merge(
      [
        http_only: true,
        path: callback_path(configuration),
        same_site: "Lax",
        secure: conn.scheme == :https
      ],
      options
    )
  end

  defp callback_path(configuration),
    do: get_in(Config.slack(configuration) || %{}, [:oauth_callback_endpoint]) || "/"

  defp generate, do: 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  defp secret(configuration) do
    case get_in(Config.slack(configuration) || %{}, [:state_secret]) do
      secret when is_binary(secret) and secret != "" ->
        {:ok, secret}

      _ ->
        {:error,
         %ConfigurationError{
           message:
             "Slack state secret missing in Juvet configuration (slack: [state_secret: ...])."
         }}
    end
  end
end
