defmodule EyeSeeYou.MixProject do
  use Mix.Project

  def project do
    [
      app: :eye_see_you,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        eye_see_you: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :ssl, :inets],
      mod: {EyeSeeYou.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2"},
      {:gen_smtp, "~> 1.2"},
      # Ajouter cette ligne
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
