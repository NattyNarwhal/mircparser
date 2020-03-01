defmodule MircParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :mircparser,
      description: description(),
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  defp description() do
    "Parses mIRC formatting into tokens or HTML."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/NattyNarwhal/mircparser"}
    ]
  end
end
