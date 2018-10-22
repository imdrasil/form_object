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
