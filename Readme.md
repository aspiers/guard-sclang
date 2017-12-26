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

If you can do something in your sclang, or in ruby, you can do it when a file changes
with guard-sclang. It simply executes the block passed to watch if a change is 
detected, and if anything is returned from the block it will be printed. For example

``` ruby
guard :sclang do
  watch /.*/ do |m|
    m[0] + " has changed."
  end
end
```

will simply print a message telling you a file has been changed when it is changed.
This admittedly isn't a very useful example, but you hopefully get the idea. To run
everything on start pass `:all_on_start` to `#guard`,

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

#### Saying the Name of the File You Changed and Displaying a Notification

``` ruby
guard :sclang do
  watch /(.*)/ do |m|
    n m[0], 'Changed'
    `say -v cello #{m[0]}`
  end
end
```

#### Rebuilding LaTeX

``` ruby
guard :sclang, :all_on_start => true do
  watch /^([^\/]*)\.tex/ do |m|
    `pdflatex -sclang-escape #{m[0]}`
    `rm #{m[1]}.log`

    count = `texcount -inc -nc -1 #{m[0]}`.split('+').first
    msg = "Built #{m[1]}.pdf (#{count} words)"
    n msg, 'LaTeX'
    "-> #{msg}"
  end
end
```

#### Check Syntax of a Ruby File

``` ruby
guard :sclang do
  watch /.*\.rb$/ do |m|
    if system("ruby -c #{m[0]}")
      n "#{m[0]} is correct", 'Ruby Syntax', :success
    else
      n "#{m[0]} is incorrect", 'Ruby Syntax', :failed
    end
  end
end
```
