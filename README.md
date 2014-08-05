Lou
===

Lou lets you define a pipeline of reversible transformations, that you can apply to any ruby object. For example, you might want to define a pipeline of [ImageMagick](http://www.imagemagick.org) operations on an image, or a sequence of API calls.

Usage
-----

You can define transformations in their own class like this:

~~~ruby
require 'lou'

class HashTransformer
  extend Lou

  transform forward { |x| x.merge(a_new_key: 'this is new') }.backward { |x| x.delete(:a_new_key) && x }
  transform forward { |x| x.flatten }.backward { |x| Hash[*x] }
end
~~~

Then you can use it like this:

~~~ruby
result = HashTransformer.apply(an_old_key: 'this is old')
# [:an_old_key, "this is old", :a_new_key, "this is new"]
original = HashTransformer.undo(result)
# {:an_old_key=>"this is old"}
~~~

Credits
-------

Lou is heavily inspired by [Hash Mapper](http://github.com/ismasan) by [Ismael Celis](http://github.com/ismasan).