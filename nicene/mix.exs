defmodule Nicene.MixProject do
  use Mix.Project

  @github_url "https://github.com/sketch-hq/nicene"

  def project do
    [
      app: :nicene,
      version: "0.4.0",
      elixir: "~> 1.7",
      start_permanent: false,
      description: "A Credo plugin containing additional checks.",
      deps: deps(),
      package: package(),

      # Docs
      name: "Nicene",
      docs: [
        main: "Readme",
        extras: ["README.md"],
        source_url: @github_url
      ]
    ]
  end

  def application(), do: []

  defp package() do
    [
      files: [
        "priv",
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Devon Estes"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp deps() do
    [
      {:assertions, "~> 0.15.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.2.0"}
    ]
  end
end
