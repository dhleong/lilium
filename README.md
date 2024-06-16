lilium
======

*Fancier Issue Tracker interactions in (Neo)Vim*

## What?

lilium is a (Neo)Vim plugin for providing fast, convenient interactions with
Github (and other issue trackers) from the comfort of your favorite editor.

In particular, it currently provides smart autocomplete for Issue and User
references from commit messages—the only parts of [lily][1] that I actually
still use, but which did not play well with [YouCompleteMe][2]. lilium has
been rewritten to take advantage of Vim 8 Async Jobs and, after much
experimentation, to work nicely alongside YouCompleteMe:

![lilium-complete-demo](https://cloud.githubusercontent.com/assets/816150/12022022/d9516fae-ad59-11e5-993e-5773312fb1ff.gif)

If you're a Neovim user, we've got you covered, too! Neovim has a separate lua
implementation that uses coroutines that should be automatically picked up by
[none-ls][3]. If you're feeling [lazy][4], the experimental LSP support is
faster and even more robust.

## How?

For vim or none-ls users, just install with your favorite package manager. To use LSP, I recommend [lazy.nvim][4]:

```lua
  {
    "dhleong/lilium",
    event = "VeryLazy",
    -- NOTE: You'll need to have rust/cargo set up to build the LSP server
    build = "cargo build",
    opts = {
      -- The LSP doesn't currently have any options, but if it did, you could pass
      -- them in this map here:
      setup_lsp = {},
    },
  },
```

### Github

Github integration should work automatically, just install and login to [gh cli][5].

### Asana

For asana, place a `.lilium.asana.json` file in your project directory, or any directory above the project. It should look like this:

```json
{
    "token": "<your personal access token here>",
    "workspace": "<your workspace id here>"
}
```

We may provide a util for selecting the correct workspace ID in the future.

## Status

Mode| Status
--|--
Vim/YCM | "Keep the lights on"
none-ls | Deprecated; prefer LSP
LSP | Actively supported!

## What else?

With [gh cli][5] set up, you can call `lilium#pr#Create()` as a wrapper around `gh pr create` that will use a new buffer in your current (Neo)Vim instance as the editor for the PR body, rather than opening a nested (Neo)Vim instance inside the terminal. Autocomplete support will of course be made available in that buffer!

[1]: https://github.com/dhleong/lily
[2]: https://github.com/Valloric/YouCompleteMe
[3]: https://github.com/nvimtools/none-ls.nvim
[4]: https://github.com/folke/lazy.nvim
[5]: https://cli.github.com
