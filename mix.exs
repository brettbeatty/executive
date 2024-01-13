defmodule Executive.MixProject do
  use Mix.Project

  def project do
    [
      app: :executive,
      name: "Executive",
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix]
      ],
      source_url: "https://github.com/brettbeatty/executive",
      docs: [
        main: "readme",
        extras: ["README.md"],
        groups_for_modules: [
          Types: [
            Executive.Types.Boolean,
            Executive.Types.Enum,
            Executive.Types.Float,
            Executive.Types.Integer,
            Executive.Types.String,
            Executive.Types.UUID
          ]
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31.1", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
