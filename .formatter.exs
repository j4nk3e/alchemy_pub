[
  import_deps: [:phoenix],
  plugins: [Quokka, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}"],
  line_length: 98,
  heex_line_length: 98,
  trailing_comma: true
]
