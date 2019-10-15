lilium
======

*Fancier Issue Tracker interactions in Vim*

## What?

lilium is a Vim plugin for providing fast, convenient interactions with
Github (and other issue trackers) from the comfort of Vim.

In particular, it currently provides smart autocomplete for Issue and User
references from commit messages—the only parts of [lily][1] that I actually
still use, but which did not play well with [YouCompleteMe][2]. lilium has
been rewritten to take advantage of Vim 8 Async Jobs and, after much
experimentation, to work nicely alongside YouCompleteMe:

![lilium-complete-demo](https://cloud.githubusercontent.com/assets/816150/12022022/d9516fae-ad59-11e5-993e-5773312fb1ff.gif)

[1]: https://github.com/dhleong/lily
[2]: https://github.com/Valloric/YouCompleteMe
