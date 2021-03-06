Lou
===

[![Build Status](https://travis-ci.org/iainbeeston/lou.svg?branch=master)](https://travis-ci.org/iainbeeston/lou)
[![Code Climate](https://codeclimate.com/github/iainbeeston/lou/badges/gpa.svg)](https://codeclimate.com/github/iainbeeston/lou)

Lou lets you define a pipeline of reversible transformations, that you can apply to any ruby object. It assumes nothing about your business logic or the objects that you're using. For example, you might want to define a pipeline of [ImageMagick](http://www.imagemagick.org) operations on an image, or a sequence of API calls. You could even use Lou as a replacement for ActiveRecord migrations.

Usage
-----

You can define transformations in their own class like this:

~~~ruby
require 'lou'

class HashTransformer
  extend Lou::Transformer

  # optional
  revert_on RuntimeError

  step up { |x|
    x.merge(a_new_key: 'this is new')
  }.down { |x|
   x.delete(:a_new_key)
   x
  }

  step up { |x|
    x.flatten
  }.down { |x|
    Hash[*x]
  }
end
~~~

Then you can use it like this:

~~~ruby
result = HashTransformer.apply(an_old_key: 'this is old')
# [:an_old_key, "this is old", :a_new_key, "this is new"]
original = HashTransformer.revert(result)
# {:an_old_key=>"this is old"}
~~~

The steps are applied in the order that they're defined, when the `apply` method is called, with each step receiving the result of the previous one. The process can be reversed using the `revert` method. Note that for each step, the input is the result of the previous step.

If `revert_on` is defined, then any completed steps will be reversed if the exception specified is raised.

Transformers can reuse other transformers as steps. In fact, any object that defines an `apply` method and a `revert` method can be used as a step.

~~~ruby
class FakeTransformer
  def self.apply(x)
    x + ["this is special"]
  end

  def self.revert(x)
    x.pop
    x
  end
end

class CompositeTransformer
  extend Lou::Transformer

  step HashTransformer
  step FakeTransformer
end

result = CompositeTransformer.apply(an_old_key: 'this is old')
# [:an_old_key, "this is old", :a_new_key, "this is new", "this is special"]
original = CompositeTransformer.revert(result)
# {:an_old_key=>"this is old"}
~~~

Credits
-------

Lou was originally inspired by [Hash Mapper](http://github.com/ismasan) by [Ismael Celis](http://github.com/ismasan) to be a way of transforming hashes, however, it evolved into a general purpose pipeline for arbitrary blocks of code.

Related
-------

* [Transproc](https://github.com/solnic/transproc)
