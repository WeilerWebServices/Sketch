![](https://travis-ci.org/awkward/sequelize-reassociate.svg)
# sequelize-reassociate
A simple abstraction for the [Sequelize](http://docs.sequelizejs.com/en/v3/) to reassociate a models associations if it ever were to be destroyed.

## What?
Sequelize-reassociate basically moves a models associations to a provided record if the parent model were to be destroyed. For example, if a `User` model owns many `Comment`s, we can transfer the `Comment`s to a Ghost-user (like GitHub does) so the context of the conversation can be preserved. It currently only works for `HasMany` associations.

## How?

1) Download the module:
```
 npm install @awkward/sequelize-reassociate --save
 ```
 
2) Require the module:
``` javascript
 const reassociate = require('@awkward/sequelize-reassociate');
```

3) Setup the module:
in your `index.js` file (or wherever you initialize Sequelize) just call the function and pass in your initialized sequelize instance. Make sure the models already have been initialized at this point.

``` javascript
  // pass in the reference to sequelize after models have been initialized
  reassociate(sequelize);
```

4) Using the module:
Now to use the module, let the models know where its associations can be moved to using a public method which returns an object:

``` javascript
const User = sequelize.define('user', {
    // snip ...
  },
  {
    classMethods: {
      associate: function(models) {
        User.hasMany(models.Comment);
      },

      reassociate: function() {
        // if the User gets destroyed, its Comments go to User with id 1
        return { 
          Comments: 1, 
        };
      }
    }
  }
});

```

Basically the heart is in the `reassociate()` method. The return value should be an object containing the association (either the Model name or the reference when using `as` in the association) and the value is the foreign key pointing to the new owner.

## License
[MIT](https://github.com/awkward/sequelize-reassociate/blob/master/LICENSE)

