defmodule Mix.Tasks.Record do
  use Mix.Task
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  @shortdoc "Re-record ExVCR cassettes for the Slack endpoints"
  def run([token]) do
    Enum.each(["rtm.connect"], fn method_name ->
      delete_cassettes(method_name)
    end)

    SlackAPI.start()

    Enum.each(["rtm.connect"], fn method_name ->
      record_successful(method_name, token)
    end)

    Enum.each(["rtm.connect"], fn method_name ->
      record_invalid_auth(method_name)
    end)
  end

  def cassette_directory_name(method_name) do
    String.replace(method_name, ".", "/")
  end

  def delete_cassettes(method_name) do
    cassette_library_dir = ExVCR.Setting.get(:cassette_library_dir)

    Mix.Task.run("vcr.delete", [
      "-d",
      "#{cassette_library_dir}/#{cassette_directory_name(method_name)}",
      "--all"
    ])
  end

  def record_invalid_auth(method_name) do
    use_cassette "#{cassette_directory_name(method_name)}/invalid_auth" do
      SlackAPI.request(method_name, %{token: "blah"})
    end
  end

  def record_successful(method_name, token) do
    use_cassette "#{cassette_directory_name(method_name)}/successful" do
      SlackAPI.request(method_name, %{token: token})
    end
  end
end
