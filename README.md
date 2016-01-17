Typeclass
=========

[![Gem Version](https://badge.fury.io/rb/typeclass.svg)](http://badge.fury.io/rb/typeclass)
[![Build Status](https://travis-ci.org/braiden-vasco/typeclass.rb.svg)](https://travis-ci.org/braiden-vasco/typeclass.rb)
[![Coverage Status](https://coveralls.io/repos/braiden-vasco/typeclass.rb/badge.svg)](https://coveralls.io/r/braiden-vasco/typeclass.rb)
[![Inline docs](http://inch-ci.org/github/braiden-vasco/typeclass.rb.svg?branch=master)](http://inch-ci.org/github/braiden-vasco/typeclass.rb)

Haskell type classes in Ruby.

Usage
-----

**The gem is under development. Don't try to use it in production code.**

To install type in terminal

```sh
gem install typeclass
```

or add to your `Gemfile`

```ruby
gem 'typeclass', '~> 0.1.1'
```

To learn how to use the gem look at the [examples](/examples/).

Concept
-------

The main goals of this project is to create statically typed subset of Ruby
inside dynamically typed Ruby programs as a set of functions which know
types of it's arguments. There is something like function decorator
which checks if function is correctly typed after it is defined.
Type declarations are needed for typeclass definition only. All other types
are known due to type inference, so the code looks like normal Ruby code.

Of course there is a runtime overhead due to the use of type classes.
Therefore another important goal is an optimiaztion which is possible
because of the known types. It can be performed with bytecode generation
at runtime. In this way the bytecode generated by Ruby interpreter
will be replaced with the optimized code generated directly from the source.
If the optimized bytecode can not be generated due to some reasons
(no back end for the virtual machine, for example), the code can be
interpreted in the usual way because it is still a normal Ruby code.

Example
-------

Please read [this article](https://www.haskell.org/tutorial/classes.html)
if you are unfamiliar with Haskell type classes (understanding of Rust
traits should be enough).

Let's look at the following example and realize which parts of the code
can be statically typed.

```ruby
Show = Typeclass.new a: Object do
  fn :show, [:a]
end

Typeclass.instance Show, a: Integer do
  def show(a)
    "Integer(#{a})"
  end
end

Typeclass.instance Show, a: String do
  def show(a)
    "String(#{a.dump})"
  end
end

puts Show.show(5) #=> Integer(5)
puts Show.show('Qwerty') #=> String("Qwerty")
```

As you can see, that there is no annoying
[typesig's](https://rubygems.org/gems/rubype),
[typecheck's](https://rubygems.org/gems/typecheck),
[sig's](https://rubygems.org/gems/sig),
and again [typesig's](https://github.com/plum-umd/rtc).
Definitions of type classes and instances, and function signatures
looks like typical Haskell code. The functions, in turn, are just
Ruby methods.

Nevertheless, the types of the arguments are known and can be checked
in `Typeclass#instance` method after it's block is executed.
