defmodule Mix.TaskMock do
  def run("app.start") do
    send(self(), :application_started)
  end
end
