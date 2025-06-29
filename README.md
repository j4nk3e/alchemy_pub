# AlchemyPub

AlchemyPub is a static site generator on fire built with Elixir & Phoenix LiveView.

It generates websites from markdown files. Changes to the source files are instantly published to all viewers. If no JavaScript is available on the client, it falls back gracefully to fully server-side rendered content. There is also an RSS feed generated from the articles.

Instead of saving generated pages as html files, they are rendered on startup and stored in memory using *ETS*. A file watcher picks up changes and broadcasts them using *PubSub*. Using the magic of *Phoenix LiveView* the change is immediately visible to all page viewers.

As a markdown parser, [Earmark](https://github.com/pragdave/earmark) is used because of its possibilities to add custom transformers. This way, `[[Wikilinks]]`-style references are resolved and anchors are automatically generated for headers.

For styling, [daisyUI](https://github.com/saadeghi/daisyui) allows easy change of themes and creation of your own style using [Tailwind](https://github.com/tailwindlabs/tailwindcss). The site is fully responsive for mobile and desktop resolutions, and supports themes for dark and light mode. Code blocks are automatically highlighted using [highlight.js](https://github.com/highlightjs/highlight.js).

Page visits are tracked anonymously. Thanks to [Phoenix Presence](https://hexdocs.pm/phoenix/Phoenix.Presence.html), it can keep track of navigation and the duration of each page visit. This also powers the live online counter in the navigation bar. The tracking data is stored in a file based SQLite database using Ecto. No external database or configuration is required. The tracking data can be viewed through the [Phoenix LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard).

## Getting Started

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Put your pages as markdown files in the `priv/pages` directory. You can read more on the [Home page](priv/pages/Home.md).

Ready to run in production? Please [check the Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Release

```sh
mix assets.deploy
MIX_ENV=prod mix release
mix phx.digest.clean --all
PHX_SERVER=true PHX_HOST=localhost SECRET_KEY_BASE="{{ key }}" _build/prod/rel/alchemy_pub/bin/alchemy_pub start
```

## Credits

AlchemyPub is originally brought to you by [j4nk.dev](https://j4nk.dev). It is published under the [Apache License 2.0](LICENSE).

## Roadmap

- [x] Add date support for articles
- [x] Use date for navigation
- [x] Menu generation & navigation
- [x] Title parsing from content header
- [x] Tags support
- [x] Toplevel pages
- [x] Icon support
- [x] Hidden pages
- [x] Write tests
- [x] Write documentation
- [x] Publish on Github
- [x] Live page add/remove support
- [x] Legal stuff
- [x] Deployment
- [x] Live viewer count
- [x] Live tracking
- [ ] Static content updates (images)
- [ ] Slide support
- [ ] Tracker visualization
- [ ] Keyboard navigation
- [ ] LiveView patch tag navigation support
