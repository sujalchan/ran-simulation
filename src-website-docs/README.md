# RAN Network Simulator developer documentation

This is a static documentation site for the current Roblox Studio and Luau implementation in `src/Places`. It has no package dependencies or build step.

Open `index.html` directly in a browser, or serve the repository root locally:

```sh
python3 -m http.server 8000
```

Then open `http://localhost:8000/src-website-docs/`.

The site has pages for both places, their simulation systems, communication flows, developer guidance, and every Luau source file. `docs-data.js` holds the page content and script/event metadata; `app.js` provides navigation, search, filtering, theme switching, and the table of contents; `styles.css` provides the responsive layout. The site defaults to dark mode, and a visitor's Light or Dark choice is saved locally. The files in `reference/` are design and project-context inputs, not runtime dependencies.

When updating the site, use the Luau source as the authority for behavior and exact paths. Check Studio object attributes and hierarchy in the Roblox place when documenting world configuration.
