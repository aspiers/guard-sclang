Guard::Sclang
=============

This [Guard](http://guardgem.org/) plugin allows you to run SuperCollider [`UnitTest` test
suites](http://doc.sccode.org/Classes/UnitTest.html) commands when
files are added or altered.


Install
-------

Make sure you have [Guard](http://guardgem.org/) installed.

Install the gem with:

    gem install guard-sclang

Or add it to your `Gemfile`:

    gem 'guard-sclang'

And then add a basic setup to your `Guardfile`:

    guard init sclang


Usage
-----

When one or more files matching a `watch` block's regular expression
changes, guard-sclang simply runs the UnitTest subclass returned by
that block:

``` ruby
guard :sclang do
  # Run any tests which are added or changed under lib/tests/
  watch(%r{lib/tests/\w.*\.sc})

  # For any class Foo added or changed under lib/classes/, run
  # the corresponding test class TestFoo
  watch(%r{lib/classes/(\w.*)\.sc}) do |m|
    classname = "Test#{m[1]}"
    puts "#{m[0]} changed; running #{classname}"
    classname
  end
end
```

### `sclang` CLI arguments

You can optionally provide arguments to be passed to `sclang`, e.g.

``` ruby
# Load the ScQT IDE classes
guard :sclang, args: ["-i", "scqt"] do
  ...
end
```

### `sclang` execution timeout

If `sclang` experiences a compilation error, it will hang, so
invocation of `sclang` is currently wrapped by
[`timeout(1)`](https://linux.die.net/man/1/timeout).  (This
currently prevents `guard-sclang` from working outside Linux,
but it should not be hard to convert the timeout mechanism to native
Ruby to fix that.)

The timeout defaults to 3 seconds, but can be changed:

``` ruby
guard :sclang, timeout: 10 do
  ...
end
```

### Other options

To run everything on start pass `:all_on_start` to `#guard`:

``` ruby
guard :sclang, all_on_start: true do
  ...
end
```


Development / support / feedback
--------------------------------

Please see [the CONTRIBUTING file](CONTRIBUTING.md).


History and license
-------------------

This plugin was based on
[`guard-shell`](https://github.com/guard/guard-shell) by Joshua
Hawxwell, so the original license has been preserved - see
[LICENSE](LICENSE).
