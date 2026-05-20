# Changelog

## v0.3.0

- Replace SVG IDs during rendering with Erlang's `:xmerl` to avoid duplicate ID collisions
- Render SVG and CSS-mode wrapper elements with `:xmerl`
- Add Iconify-style dimension calculation and `1em` defaults
- Add `color`, `inline`, `mask`, and `bg` render options
- Preserve IconifyJSON metadata on `%Iconify.Set{}`

## v0.2.0

- Align IconifyJSON parsing with Elixir structs and Jason encoding
- Add canonical `Iconify.SVG` rendering module
- Resolve Iconify aliases with dimensions, rotations, and flips
- Use Iconify's 16x16 default dimensions
- Make `req` a required dependency for fetching icons
- Add CI checks with Credo, Reach smell checks, ExDNA, and tests
- Polish README and package metadata for the `elixir-volt` organization

## v0.1.0

- Initial release
- Icon struct and Set parsing
- SVG rendering with customizable attributes
- Fetcher for NPM packages and Iconify API
