---
layout: fragment
date: 2024-06-30
title: "Enough Sublime Text"
permalink: /enough-sublime-text/
---

## Navigate files

- `cmd-t` or `cmd-p` to open the file catalog.
- Only type parts of file names or paths.
- The file catalog saves the previous searches and will get better and better.
- When you need to open several files, don't press `enter`, press `right arrow` to open the file currently highlighted, and keep the file catalog active. Once you opened all your files, either press `return` or `enter` if you're on the last file you need.
- To jump to a specific line, prefix your search with `:` as in `:100` will jump to line 100.
- To jump to a specific symbol, prefix your search with `@`, as in `@gateway_params`.
- To create a word search - like `cmd-f` - in the file, prefix your file catalog search with `#`.
- You can combine these parameters: `gate contr @ index` will check for `GatewaysController#index` 👌. Useful if you know where you want to navigate.

Source: [Easily open and navigate your files in Sublime Text!](https://www.youtube.com/watch?v=YH6u2PRPfpg){:target="\_blank"}
