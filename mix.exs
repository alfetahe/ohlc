defmodule OHLC.MixProject do
  use Mix.Project

  def project do
    [
      app: :ohlc,
      version: "1.1.1",
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Package for generating OHLC candles from trades."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["GPL-3.0"],
      links: %{"GitHub" => "https://github.com/tradebase-technology/ohlc"}
    ]
  end
end
