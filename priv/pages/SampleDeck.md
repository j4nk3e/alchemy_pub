---
deck: true
title: Sample Deck
tags: Speaking
qr: true # enabled by default
---

# [[LiveDeck]]

---

## Styling

---

# Headers H1

## H2

### H3

#### H4

---

### Styling text

> a block quote.

*emphasized text*

**strong emphasis**

~~strikethrough~~

Text with  
line breaks  
in it

---

### Code blocks

This is how you do a code block with syntax highlighting:

```elixir
{
  title,
  ast
  |> Earmark.Transform.map_ast(postprocessor)
  |> Earmark.transform()
}
```

---

### Images

![image](images/Tärnättholmarna.jpg)

*With some text*

---

#### Lists

1. This is a list item.
    > containing a block quote

* List
  * sublist
  * test

> and a slightly longer block quote forcing a wrapped line if the text is too long

---

### Overflow?

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

#### Too much content gets cut off

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?

---

### Tables

| a   |   b   |
| --- | :---: |
| 1   |   2   |
| 3   |   4   |

| a lot more content   |    with breaking lines forcing a wrapped line if the text is too long labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi  |
| more content   |    with breaking lines   |

---

## Keybindings

---

### Fullscreen

Press
<kbd class="kbd">f</kbd>
for fullscreen

or click the slide

---

## Navigate

Press
<kbd class="kbd">◀︎</kbd>
or
<kbd class="kbd">▶︎</kbd>

to navigate to the previous/next slide

---

## Overview

(only available as an [Admin](/dev/dashboard))

Press
<kbd class="kbd">a</kbd>
for

### all slides

Click a slide in the overview to jump directly to it

---

## Jump

Press
<kbd class="kbd">home</kbd>
or
<kbd class="kbd">end</kbd>

to jump to the first/last slide of the deck

---

### end

You can find more documentation here: [[LiveDeck]]
