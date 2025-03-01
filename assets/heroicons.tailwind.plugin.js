const fs = require("fs");
const path = require("path");

module.exports = function ({ matchComponents, theme }) {
  let iconsDir = path.join(process.cwd(), "deps/heroicons/optimized");
  let values = {};
  let icons = [
    ["", "/24/outline"]
  ];
  safelist = [
    'bg-accent',
    'accent',
    'hero-home-modern',
    'hero-scale',
    'hero-document',
    'hero-identification',
    'hero-musical-note',
    'hero-code-bracket',
    'hero-envelope',
    'hero-globe-alt',
    'prose',
    'not-prose',
    'badge',
    'badge-primary',
    'badge-secondary',
    'badge-tertiary',
    'badge-outline',
  ],
  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      let name = path.basename(file, ".svg") + suffix;
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
    });
  });
  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");
        let size = theme("spacing.6");
        if (name.endsWith("-mini")) {
          size = theme("spacing.5");
        } else if (name.endsWith("-micro")) {
          size = theme("spacing.4");
        }
        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          mask: `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: size,
          height: size,
        };
      },
    },
    { values },
  );
};