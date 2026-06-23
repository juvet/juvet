defmodule Juvet.SlackAPITest do
  use ExUnit.Case, async: true

  alias Juvet.SlackAPI

  describe "parse_response/1" do
    test "decodes a JSON body into an atom-keyed map" do
      response = {:ok, %HTTPoison.Response{status_code: 200, body: ~s({"ok":true,"foo":"bar"})}}

      assert {:ok, %{ok: true, foo: "bar"}} = SlackAPI.parse_response(response)
    end

    test "surfaces a 429 as a ratelimited body with retry_after from the header" do
      response =
        {:ok, %HTTPoison.Response{status_code: 429, headers: [{"Retry-After", "12"}], body: ""}}

      assert {:ok, %{ok: false, error: "ratelimited", retry_after: 12}} =
               SlackAPI.parse_response(response)
    end

    test "matches the Retry-After header case-insensitively" do
      response =
        {:ok, %HTTPoison.Response{status_code: 429, headers: [{"retry-after", "5"}], body: ""}}

      assert {:ok, %{retry_after: 5}} = SlackAPI.parse_response(response)
    end

    test "defaults retry_after when the header is missing or unparseable" do
      missing = {:ok, %HTTPoison.Response{status_code: 429, headers: [], body: ""}}

      garbage =
        {:ok, %HTTPoison.Response{status_code: 429, headers: [{"Retry-After", "soon"}], body: ""}}

      assert {:ok, %{retry_after: 30}} = SlackAPI.parse_response(missing)
      assert {:ok, %{retry_after: 30}} = SlackAPI.parse_response(garbage)
    end
  end

  describe "render_response/1" do
    test "turns a 429 into a ratelimited error tuple with retry_after" do
      response =
        {:ok, %HTTPoison.Response{status_code: 429, headers: [{"Retry-After", "20"}], body: ""}}

      assert {:error, %{ok: false, error: "ratelimited", retry_after: 20}} =
               SlackAPI.render_response(response)
    end

    test "returns an ok tuple for a successful body" do
      response = {:ok, %HTTPoison.Response{status_code: 200, body: ~s({"ok":true})}}

      assert {:ok, %{ok: true}} = SlackAPI.render_response(response)
    end

    test "returns an error tuple for an ok:false body" do
      response =
        {:ok,
         %HTTPoison.Response{status_code: 200, body: ~s({"ok":false,"error":"invalid_auth"})}}

      assert {:error, %{ok: false, error: "invalid_auth"}} = SlackAPI.render_response(response)
    end
  end
end
