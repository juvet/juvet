defmodule Juvet.JSONTest do
  use ExUnit.Case, async: false

  alias Juvet.JSON

  defmodule FakeJSON do
    def encode!(_data), do: ~s({"fake":true})
    def decode(_data, opts), do: {:ok, %{fake: opts}}
    def decode!(_data, opts), do: %{fake: opts}
  end

  setup do
    on_exit(fn ->
      Application.delete_env(:juvet, :json_library)
      Application.delete_env(:juvet, :json_encoder)
    end)
  end

  test "defaults to Jason" do
    assert JSON.library() == Jason
    assert JSON.encode!(%{a: 1}) == ~s({"a":1})
    assert {:ok, %{a: 1}} = JSON.decode(~s({"a":1}), keys: :atoms)
    assert JSON.decode!(~s({"a":1})) == %{"a" => 1}
  end

  test "uses the configured :json_library" do
    Application.put_env(:juvet, :json_library, FakeJSON)

    assert JSON.encode!(%{}) == ~s({"fake":true})
    assert {:ok, %{fake: [keys: :atoms]}} = JSON.decode("{}", keys: :atoms)
  end

  test "falls back to the deprecated :json_encoder" do
    Application.put_env(:juvet, :json_encoder, FakeJSON)

    assert JSON.library() == FakeJSON
  end

  test "prefers :json_library over :json_encoder" do
    Application.put_env(:juvet, :json_encoder, FakeJSON)
    Application.put_env(:juvet, :json_library, Jason)

    assert JSON.library() == Jason
  end
end
