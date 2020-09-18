Application.load(:juvet)

for app <- Application.spec(:juvet, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
