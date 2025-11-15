---
rank: 1
icon: presentation-chart-bar
title: LiveDeck
tags:
  - Documentation
  - Speaking
---

# LiveDeck: Interactive Presentations

Welcome to LiveDeck, AlchemyPub's built-in framework for turning any markdown page into a dynamic, interactive presentation. Creating and sharing a slideshow is as simple as writing a post.

Individual slide pages are separated using the `hr` tag or markdown `---` like so:

---

## 🚀 Getting Started: Creating a Deck

To transform any page into a presentation, simply add the following line to the page's YAML frontmatter:

```
---
title: My Awesome Presentation
deck: true
tags: [Conference, Tech]
---
```

Once enabled, your page will appear in a special "Decks" area in the main menu. All your other frontmatter settings, like tags or hidden, will continue to work as expected.

For easy sharing, the menu will automatically display a QR code that your audience can scan to join the live presentation on their devices.

[➡️ Check out an Example Deck](/sampledeck)

## 🧑‍💻 Admin & Presenter Features

To access presenter controls, you must first log in as an admin.
Becoming an Admin

1. Set the `AUTH_USERNAME` and `AUTH_PASSWORD` environment variables for your AlchemyPub instance (only required in `MIX_ENV=prod`).
2. Navigate to the [LiveDashboard](/dev/dashboard) in your browser (and log in when prompted).
3. Navigate back to your page.
4. An "Admin" badge will appear in the menu, confirming your status for the current session.

### Preview

- Preview: The next slide will be displayed below the current slide.
- Speaker notes: Code blocks with the `notes` class will be hidden from the slides, but are visible in the preview. You can use them to put your speaker notes on the next slide. Example:

  ~~~markdown
  ```notes
  Put your speaker notes here
  ```
  ~~~

### Presentation Control

As an admin, you control the presentation for all viewers. Non-admin visitors can only navigate up to the slide you are currently on.

- Follow Mode: When they press the "Follow" button, your audience's devices will automatically sync to the slide you are currently viewing in real-time.
- Auto-Follow Link: You can share a special link like [/sampledeck?p=-1](/sampledeck?p=-1) to automatically enable follow mode for anyone who opens it.
- By default, all decks are unlocked and fully navigable by anyone until an admin takes control.

### Slide Overview

Press the `A` key or the All button to see a complete overview of all slides in your deck. This is useful for quickly jumping to a specific slide. This is only possible as an Admin.
- Navigation: Clicking a slide in the overview will jump directly to this slide.
- Printing: From the slide overview screen (press `A`), use your browser's print function (`Ctrl+P` or `Cmd+P`) to generate a print-friendly layout or PDF of all your slides.

## ⌨️ General Features & Navigation

LiveDeck includes several features for a smooth viewing experience.

- Fullscreen Mode: Press the `F` key or click on a slide to enter and exit fullscreen mode.
- Progress Indicator: A subtle progress bar at the bottom of the slides shows how far you are in the presentation, giving you and your audience a clear sense of pace.
- QR-Code: The menu will always display a QR code linking to the current slide. This can be disabled by setting `qr: false` in the YAML frontmatter.

### Keyboard Shortcuts

Navigate your presentation with these handy keyboard shortcuts.

| Key            | Action                                       |
| -------------- | -------------------------------------------- |
| ➡️ `ArrowRight` | Go to the next slide                         |
| ⬅️ `ArrowLeft`  | Go to the previous slide                     |
| `Home`         | Jump to the first slide                      |
| `End`          | Jump to the last slide (enables Follow Mode) |
| `F`            | Toggle fullscreen mode                       |
| `Esc`          | Exit fullscreen mode                         |
| `M`            | Mute slides                                  |
| `A`            | Show all slides (Admin only)                 |
