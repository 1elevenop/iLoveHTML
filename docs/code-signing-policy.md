# Code signing policy

**Status: not signed yet.** iLoveHTML releases are not code-signed today.
Windows may show "Windows protected your PC" (choose More info → Run anyway).
We plan to apply to the SignPath Foundation free code signing program for
open-source projects. This page will change when a signing certificate is in use.

## What will be signed

Only the iLoveHTML builder itself: `iLoveHTML.exe` and its files in the
Windows release ZIP, built from this repository by the GitHub Actions
workflow. Apps that people build with iLoveHTML are **not** signed by this
project; their authors sign them (or leave them unsigned).

## Team roles

| Role | Who |
|---|---|
| Authors / committers | [1elevenop](https://github.com/1elevenop) |
| Reviewers | [1elevenop](https://github.com/1elevenop) |
| Approvers (approve each signing request) | [1elevenop](https://github.com/1elevenop) |

Every release is approved by hand before signing.

## Privacy

See the [Privacy Policy](privacy.md). In short: no accounts, analytics or
tracking. The app contacts the network only when you ask it to, plus an
update check to GitHub that you can turn off in Settings → About.

<!-- After SignPath approval, add this exact line (required by their terms):
Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org)
-->
