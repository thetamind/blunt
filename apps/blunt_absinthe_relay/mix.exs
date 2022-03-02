defmodule BluntAbsintheRelay.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      version: @version,
      app: :blunt_absinthe_relay,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/blunt-elixir/blunt_absinthe_relay",
      package: [
        description: "Absinthe Relay macros for `blunt` commands and queries",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/blunt-elixir/blunt_absinthe_relay"}
      ],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    blunt(Mix.env()) ++
      [
        {:absinthe, "~> 1.7", override: true},
        {:absinthe_relay, "~> 1.5"},

        # For testing
        {:etso, "~> 0.1.6", only: [:test]},
        {:faker, "~> 0.17.0", optional: true, only: [:test]},
        {:ex_machina, "~> 2.7", optional: true, only: [:test]},
        {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
        {:elixir_uuid, "~> 1.6", only: [:dev, :test], override: true, hex: :uuid_utils},

        # generate docs
        {:ex_doc, "~> 0.28", only: :dev, runtime: false}
      ]
  end

  # defp blunt(:prod) do
  #   [
  #     {:blunt, github: "blunt-elixir/blunt", ref: "reorg", sparse: "apps/blunt"},
  #     {:blunt_absinthe, github: "blunt-elixir/blunt", ref: "reorg", sparse: "apps/blunt_absinthe"}
  #   ]
  # end

  defp blunt(_env) do
    [
      {:blunt, path: "../blunt", override: true},
      {:blunt_absinthe, path: "../blunt_absinthe"}
    ]
  end
end
