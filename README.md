# Guard::Sclang

This little guard allows you to run sclang commands when files are altered.


## Install

Make sure you have [guard](http://github.com/guard/guard) installed.

Install the gem with:

    gem install guard-sclang

Or add it to your Gemfile:

    gem 'guard-sclang'

And then add a basic setup to your Guardfile:

    guard init sclang


## Usage

When one or more files matching a `watch` block's regular expression
changes, guard-sclang simply executes the SuperCollider file(s)
returned by that block

``` ruby
guard :sclang do
  watch /.*/ do |m|
    m[0] + " has changed."
  end
end
```

will simply print a message telling you a file has been changed when
it is changed.  This admittedly isn't a very useful example, but you
hopefully get the idea. To run everything on start pass
`:all_on_start` to `#guard`,

``` ruby
guard :sclang, :all_on_start => true do
  # ...
end
```

There is also a shortcut for easily creating notifications,

``` ruby
guard :sclang do
  watch /.*/ do |m|
    n m[0], 'File Changed'
  end
end
```

`#n` takes up to three arguments; the first is the body of the message, here the path
of the changed file; the second is the title for the notification; and the third is
the image to use. There are three (four counting `nil` the default) different images
that can be specified `:success`, `:pending` and `:failed`.


### Examples

fixme
