---
deck: true
title: LiveDeck
tags: Speaking
---

# LiveDeck

---

## Code blocks

This is how you do a code block:

```elixir
{
  title,
  ast
  |> Earmark.Transform.map_ast(postprocessor)
  |> Earmark.transform()
}
```

---

### Styling text

> a block quote.

*emphasized text*

**strong emphasis**

~~strikethrough~~

---

### Images

![image](images/Tärnättholmarna.jpg)

---

#### Lists

1. This is a list item.

 > containing a block quote

* List
  * sublist
  * test

---

## Tables

| a   |   b   |
| --- | :---: |
| 1   |   2   |
| 3   |   4   |
