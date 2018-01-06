[![Build Status](https://travis-ci.org/aspiers/guard-sclang.svg?branch=master)](https://travis-ci.org/aspiers/guard-sclang)

Guard::Sclang
=============

This [Guard](http://guardgem.org/) plugin allows you to run
SuperCollider [`UnitTest` test
suites](http://doc.sccode.org/Classes/UnitTest.html) automatically
when files are added or altered, so that you can immediately see the
impact of code changes on your tests.


Installation
------------

Make sure you have [Guard](http://guardgem.org/) installed.

Install the gem with:

    gem install guard-sclang

Or, better, add it to your `Gemfile`, and then use
[Bundler](http://bundler.io/) to install it:

    echo "gem 'guard-sclang'" >> Gemfile
    bundle install


Configuring a `Guardfile`
---------------------------

Before you can launch Guard, you need to configure a `Guardfile` which
tells Guard which of your SuperCollider tests to run via the
`guard-sclang` plugin.

You can create a stub `Guardfile` from a built-in template via:

    bundle exec guard init sclang

The rest of this section explains how to configure the `Guardfile`.

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


Usage
-----

Once you have set up your `Guardfile` with the `guard-sclang` plugin
enabled, you are ready to launch Guard.

`guard-sclang` assumes that the `sclang` interpreter is to be found
somewhere on your `$PATH`.  If you installed SuperCollider on Linux
via a distribution package, this should happen automatically, in which
case you can simply launch Guard by typing this into your shell:

    bundle exec guard

However if you installed from source, or you are using MacOS, maybe
`sclang` won't be on the `$PATH`, in which case you will need to set
it.  This can either be done temporarily for each invocation of Guard,
e.g.

    PATH=/path/to/dir/containing/sclang:$PATH bundle exec guard

or by configuring your interactive shell setup (e.g. `~/.bashrc`) to
set `$PATH` on startup.


Development / support / feedback
--------------------------------

Please see [the CONTRIBUTING file](CONTRIBUTING.md).


History and license
-------------------

This plugin was based on
[`guard-shell`](https://github.com/guard/guard-shell) by Joshua
Hawxwell, so the original license has been preserved - see
[LICENSE](LICENSE).
