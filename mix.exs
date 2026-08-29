defmodule CodexEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :codex_ex,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for the Codex app-server JSON-RPC protocol",
      source_url: "https://github.com/gersmann/codex-ex",
      docs: [main: "readme", extras: ["README.md"]],
      package: package()
    ]
  end

  def application do
    [
      mod: {CodexEx.Application, []},
      extra_applications: [:logger, :crypto, :public_key]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:mint_web_socket, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:bandit, "~> 1.5", only: :test},
      {:websock_adapter, "~> 0.5", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gersmann/codex-ex"},
      files: ~w(lib priv mix.exs README.md LICENSE .formatter.exs)
    ]
  end
end
