defmodule MapDiff.Mixfile do
  use Mix.Project

  def project do
    [app: :map_diff,
     version: "1.3.2",
     # build_path: "../../_build",
     # config_path: "../../config/config.exs",
     # deps_path: "../../deps",
     # lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     description: description(),
     package: package()

    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:earmark, ">= 0.0.0", only: [:dev, :docs]},    # Markdown, dependency of ex_doc
      {:ex_doc, "~> 0.11",   only: [:dev, :docs]},    # Documentation for Hex.pm
      {:inch_ex, ">= 0.0.0", only: [:docs]},     # Inch CI documentation quality test.

      {:tensor, "~> 2.1"}
    ]
  end


  defp description do
    """
    Calculates the difference between two (nested) maps,
    and returns a map representing the patch of changes.
    """
  end

  defp package do
    [# These are the default files included in the package
      name: :map_diff,
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Wiebe-Marten Wijnja/Qqwy"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Qqwy/elixir_map_diff/"}
    ]
  end

end
