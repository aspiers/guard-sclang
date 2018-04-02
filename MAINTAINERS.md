# Maintaining `guard-sclang`

## Making a new release

Should be as simple as:

- Ensure `lib/guard/sclang/version.rb` has a new version number
  which adheres to [Semantic Versioning](https://semver.org/).

- Ensure your working tree is clean, with no uncommitted changes.

- Ensure your `git` config has `user.signingkey` set, and
  `tag.forcesignannotated` set to `true`.

- Run: `bundle exec rake release`
