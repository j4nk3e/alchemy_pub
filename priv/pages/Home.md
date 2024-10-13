---
rank: 0
title: Home
tags:
  - Documentation
---

# Welcome to AlchemyPub

This page explains in detail how AlchemyPub works and how you can set it up.

## Menu

On the left, you can see the menu generated from all your files in the `priv/pages` directory. It consists of three parts:

- On the top are [Pages](#pages)
- In the middle, [Posts](#posts) are ordered by date
- On the bottom, the list of page tags is shown

Menu navigation is handled by Phoenix LiveView `patch` actions. This means navigating the menu does not trigger a full page reload, it only fetches the new content using websockets and swaps out the relevant parts.

You can set up the page structure as follows.

## YAML Frontmatter

Every page can be configured using the YAML frontmatter. Begin the page using:

```yaml
---
key: value
---
```

to set properties for each page.

The following properties are available on all pages:

- `title`: This sets the title that is shown in the menu. If the title property does not exist, the content of the first header `<h1>` on the page is used. If there is no header, it defaults to the file name. Example:

  ```yaml
  ---
  title: Home
  ---
  ```

- `tags` gives each page a list of tags. Pages can be filtered through the tag list on the bottom of the menu. Example:

  ```yaml
  ---
  tags:
    - Example
    - Documentation
  ---
  ```

- `hidden` hides a page from the menu. It can still be accessed directly, using a link. You can find a hidden page under [[Secret]]. Example:

  ```yaml
  ---
  hidden: true
  ---
  ```

- `nobot` hides a page in the menu from webcrawlers that do not handle websocket connections. This is done by filtering it during the inital page delivery. When a browser connects through the websocket, it will show up immediately to the user. The page can still be accessed directly, using a link. Be aware, that by linking the page, it will be picked up by bots again. You can find such a page under [[Imprint]]. Example:

  ```yaml
  ---
  nobot: true
  ---
  ```

## Pages

Pages live in the root of the menu. Their order is manually defined using the `rank` property. The page with the lowest rank automatically becomes the home page accessible from the root path `/` of the page. Example:

```yaml
---
rank: 0
---
```

### Icons

Pages can be given an icon using the `icon` property. Example:

```yaml
---
icon: home-modern
---
```

It uses the [Heroicons](https://heroicons.com) library. To make sure your icons are added to the compiled tailwind output, you have to add it to the `module.exports.safelist` in `assets/tailwind.config.js`. It is possible to whitelist all icons using a pattern, however this adds around 1MB to the generated CSS.

## Posts

All files that do not have a `rank` property automatically become [Posts](#posts). Posts are sorted by date on the menu, grouped by their year.

The date of a file can be specified using the `date` property in the frontmatter. Dates are specified using a `YYYY-MM-DD` string. Example:

```yaml
---
date: 1845-01-29
---
```

If no date is set in the frontmatter, it will default to the modification date of the file. This allows you to drop new files in the `pages` folder without frontmatter, and they will still be ordered reasonably. Be aware that if you change a file, the date will also change. To keep the date of posts fixed, please use the `date` property.

## Links & Navigation

For all files, a url will be generated from its filename to link to the file. Spaces and special characters will be stripped out, and links will work case insensitive. [Pages](#pages) are referenced by name only. [Posts](#posts) will always use the date and name in the path.

Additionally, posts can also be accessed only by their date. The title is only required if multiple posts share the same date. If only the title or the date is given or either one is incorrect, the post will still be found. This allows links to posts to be more stable if either the date or the title is changed later.

The following links all reference the same page:

- [Date and title: 1845-01-29/the-raven](1845-01-29/the-raven)
- [Date only: 1845-01-29](1845-01-29)
- [Title only: the-raven](the-raven)
- [Wrong date: 2000-01-29/the-raven](2000-01-29/the-raven)
- [Wrong title: 1845-01-29/the-chicken](1845-01-29/the-chicken)

## Syntax highlighting

Code blocks get highlighted on the client using `hljs`. To configure supported languages, add them to your `assets/js/app.js`. YAML, JavaScript (to render the documentation) and of course Elixir are supported by default. Example:

```javascript
hljs.registerLanguage("elixir", require("highlight.js/lib/languages/elixir"));
```

A list of all supported languages can be found [here](https://github.com/highlightjs/highlight.js/blob/main/SUPPORTED_LANGUAGES.md).

## Analytics

In the `dev` environment, the PhoenixAnalytics dashboard can be accessed under [/dev/analytics](/dev/analytics). To allow access in production, make sure the access to the analytics page is secured (if you don't want it to be public). This can be set up in the `lib/alchemy_pub/router.ex` in the `scope "/dev"` block.
