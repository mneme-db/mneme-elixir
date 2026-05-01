defmodule MnemeDbClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :mnemedb_client,
      version: "0.1.0",
      elixir: "~> 1.18",
      preferred_cli_env: [
        {:"test.ci", :test},
        {:coveralls, :test},
        {:"coveralls.detail", :test},
        {:"coveralls.post", :test},
        {:"coveralls.github", :test}
      ],
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      description: "Idiomatic Elixir client for the mneme embedded vector database core",
      package: package(),
      docs: docs(),
      aliases: aliases(),
      source_url: "https://github.com/mneme-db/mneme-elixir",
      homepage_url: "https://github.com/mneme-db/mneme-elixir",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MnemeDbClient.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:zigler, "~> 0.15", runtime: false},
      {:zigler_precompiled, "~> 0.1"},
      {:nimble_pool, "~> 1.1"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "VERSIONING.md",
        "docs/design/architecture.md",
        "docs/design/nif_strategy.md",
        "docs/design/precompiled_nifs.md",
        "docs/design/resource_management.md"
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "test.ci": [
        "format --check-formatted",
        "credo --strict",
        "compile --warnings-as-errors",
        "test"
      ]
    ]
  end

  defp package do
    [
      name: "mnemedb_client",
      files: [
        "lib",
        "native",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "VERSIONING.md"
      ],
      maintainers: ["Thanos Vassilakis"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/mneme-db/mneme-elixir",
        "Core Engine" => "https://github.com/mneme-db/mneme"
      }
    ]
  end
end
