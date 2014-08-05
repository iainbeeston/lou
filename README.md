Lou
===

[![Build Status](https://travis-ci.org/iainbeeston/lou.svg?branch=master)](https://travis-ci.org/iainbeeston/lou)
[![Code Climate](https://codeclimate.com/github/iainbeeston/lou/badges/gpa.svg)](https://codeclimate.com/github/iainbeeston/lou)

Lou lets you define a pipeline of reversible transformations, that you can apply to any ruby object. For example, you might want to define a pipeline of [ImageMagick](http://www.imagemagick.org) operations on an image, or a sequence of API calls.

Usage
-----

You can define transformations in their own class like this:

~~~ruby
require 'lou'

class HashTransformer
  extend Lou

  transform forward do |x|
    x.merge(a_new_key: 'this is new')
  end.backward do |x|
   x.delete(:a_new_key)
   x
  end

  transform forward do |x|
    x.flatten
  end.backward do |x|
    Hash[*x]
  end
end
~~~

Then you can use it like this:

~~~ruby
result = HashTransformer.apply(an_old_key: 'this is old')
# [:an_old_key, "this is old", :a_new_key, "this is new"]
original = HashTransformer.undo(result)
# {:an_old_key=>"this is old"}
~~~

The transforms are applied in the order that they're defined using the ~apply~ function, with each transform receiving the result of the previous one. The process can be reversed using the ~undo~ function.

Credits
-------

Lou is heavily inspired by [Hash Mapper](http://github.com/ismasan) by [Ismael Celis](http://github.com/ismasan).