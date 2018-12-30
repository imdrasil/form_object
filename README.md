# FormObject

This shard gives you an opportunity to separate form data from your model. Also you can move ny data-specific validation to form object level and be free from coercing data from the request instance - it will take care of it.

> ATM FormObject is designed to be used in air with [Jennifer](https://github.com/imdrasil/jennifer.cr) ORM but can be also used as ORM-agnostic tool but with some limitations.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  form_object:
    github: imdrasil/form_object
```

## Usage

Require FromObject somewhere after Jennifer:

```crystal
require "jennifer"
# ...
require "form_object"
require "form_object/coercer/pg" # if you are going to use PG::Numeric
```

Also it is important to notice that `form_object` modifies `HTTP::Request` core class to store body in private variable `@cached_body : IO::Memory?` of maximum size 1 GB. This is done because to allow request body multiple reading.

### Defining Form

Forms are defined in the separate classes. Often (but not necessary) these classes are pretty similar to related models:

```crystal
class PostForm < FormObject::Base(Post)
  attr :title, String
end
```

Use `.attr` macro to define a field.

Also you can specify [any validation](https://github.com/imdrasil/jennifer.cr/blob/master/docs/validation.md) supported by Jennifer model.

```crystal
class PostForm < FormObject::Base(Post)
  attr :title, String

  validates_length :title, in: 1...255
end

f = PostForm.new(Post.new)
f.title = "a" * 255
f.valid? # false
f.errors # Jennifer::Model::Errors
```

Resource model translation messages are used for the form.

#### Nesting

To define nested object use `.object` macro:

```crystal
class AddressForm < FormObject::Base(Address)
  attr :street, Address
end

class ContactForm < FormObject::Base(Contact)
  object :address, Address
end
```

For collection use `.collection` macro.

##### Populators

In `#verify`, nested hash is passed. Form object by default will try to match nested hashes to the nested forms. But sometimes the incoming hash and the existing object graph are not matching 1-to-1. That's where populators will help you.

You have to declare a populator when the form has to deserialize nested input. ATM populator may be only a method name.

Populator is called only if an incoming part for particular object is present.

```crystal
# request with { addresses: [{ :street => "Some street" }]} payload
form.verify(request) # will call populator once
# request with { addresses: [] of String} payload
form.verify(request) # will not call populator
```

Populator for collection is executed for every collection part in the incoming hash.

```crystal
class ContactForm < FormObject::Base(Contact)
  collection :addresses, Address, populator: :address_populator

  def address_populator(collection, index, **opts)
    if item = collection[index]?
      item
    else
      item = AddressForm.new(Address.new({contact_id: resource.id}))
      collection << item
      item
    end
  end
```

This populator checks if a nested form is already existing by using `collection[index]?`. While the `index` argument represents where we are in the incoming array traversal, `collection` is identical to `self.addresses`.

It is very important that each populator invocation returns the *form* not the model.

##### Delete

Populators can not only create, but also destroy. Let's say the following input is passed in.

```crystal
# request with the { addresses: [{:street => "Street", :id => 2, :_delete => "1" }] } payload
form.verify(request)
```

You can implement your own deletion:

```crystal
class ContactForm < FormObject::Base(Contact)
  collection :addresses, Address, populator: :address_populator

  property ids_to_destroy : Array(Int32)

  def address_populator(context, **opts)
    item = addresses.find { |address| address.id == context["id"] }

    if context["_delete"]
      addresses.delete(item)
      ids_to_destroy << item.id
      skip
    end

    if item
      item
    else
      item = AddressForm.new(Address.new)
      collection << item
      item
    end
  end

  def persist
    super.tap do |result|
      next unless result
      ids = ids_to_destroy
      Address.where { _id.in(ids) }.destroy
    end
  end
end
```

##### Skip

Populators can skip processing of a part by invoking `#skip`. This method raises `FormObject::SkipException` which makes form object to ignore particular part.

#### Reusability

To reuse common attributes or functionality you can use modules inclusion and inheritance:

```crystal
module PostTitle
  include FormObject::Module

  attr :title, String
end

module PostText
  include FormObject::Module

  attr :text, String
end

module BasePostAttributes
  include PostTitle
  include PostText
end

class PostForm < FormObject::Base(Post)
  include BasePostAttributes

  attr :release_date, Time

  validates_length :title, in: 1...255
end

class AdvancedPostForm < PostForm
  attr :likes, Int32
end
```

### Create Form

```crystal
class PostsController < ApplicationController
  def edit
    @form = PostForm.new(Post.find!(params["id"]))
    render("edit.slang")
  end
end
```

Form will automatically read attributes from the model.

### Validation

To save model you should validate input data:

```crystal
class PostsController < ApplicationController
  def create
    @form = PostForm.new(Post.new)
    if @form.verify(request) && @form.save
      flash["success"] = "Created Post successfully."
      redirect_to "/posts"
    else
      flash["danger"] = "Could not create Post!"
      render("new.slang")
    end
  end
end
```

The `#verify` method parses data from the given request object and updates form attributes - the underlying model at this step remains unchanged. Next if runs defined validations and returns whether they succeed.

### Data Synching

After validation you can call `#save` (as in example above) and let FormObject take care of model persistence. Also you can use `#sync` to only write attributes from form to the resource and do everything else by your own.

#### Custom Persistence Mechanism

You can define your own way of model persistence at the form level implementing own `#persist` method:

```crystal
class PostForm < FormObject::Base(Post)
  attr :title, String

  def persist
    resource.save
    # some other logic goes here
  end
end
```

## Contributing

1. Fork it (<https://github.com/imdrasil/form_object/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

> FormObject is heavily inspired by [reform](https://github.com/trailblazer/reform) ruby gem.

- [imdrasil](https://github.com/imdrasil) Roman Kalnytskyi - creator, maintainer
