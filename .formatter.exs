[
  import_deps: [:phoenix],
  plugins: [Quokka, FreedomFormatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}"],
  trailing_comma: true,
]
