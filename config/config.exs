import Config

with :test <- config_env() do
  config :executive, Mix.Task, Mix.TaskMock
end
