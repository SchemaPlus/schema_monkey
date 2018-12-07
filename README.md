[![Gem Version](https://badge.fury.io/rb/schema_monkey.svg)](http://badge.fury.io/rb/schema_monkey)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_monkey.svg)](http://travis-ci.org/SchemaPlus/schema_monkey)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/schema_monkey.svg)](https://coveralls.io/r/SchemaPlus/schema_monkey)
[![Dependency Status](https://gemnasium.com/lomba/schema_monkey.svg)](https://gemnasium.com/SchemaPlus/schema_monkey)

# SchemaMonkey

SchemaMonkey is a behind-the-scenes gem to make it easy to write extensions to ActiveRecord.  It provides:

* A simple convention-based mechanism to insert modules into ActiveRecord modules.
* A simple convention-based mechanism to create and use [Modware](https://rubygems.org/gems/modware) middleware stacks.

SchemaMonkey by itself doesn't add any behavior -- SchemaMonkey is intended to make it easy to add clients that define methods and stacks, that are then available to other clients or the app.  (In particular, most clients of SchemaMonkey will depend on [schema_plus_core](https://github.com/SchemaPlus/schema_plus_core), which is a SchemaMonkey client that provides an "internal extension API" to ActiveRecord.)

## Installation

As usual:

```ruby
gem "schema_monkey"                 # in a Gemfile
gem.add_dependency "schema_monkey"  # in a .gemspec
```

## Usage

SchemaMonkey works with the notion of a "client" -- which is a module containining definitions.  A typical SchemaMonkey client looks like

```ruby
require 'schema_monkey'
require 'other-client1'   # make sure clients you depend on are registered
require 'other-client2'   # first, if/as needed.

module MyClient

  module ActiveRecord
    #
    # active record extensions, if any
    #
  end

  module Middleware
    #
    # middleware stack modules, if any
    #
  end

end

SchemaMonkey.register MyClient     # <--- That's it!  No configuration needed
```

of course a typical client will be split into files corresponding to submodules; e.g. here's the top level of [schema_plus_indexes](https://github.com/SchemaPlus/schema_plus_indexes):

```ruby
require 'schema_plus/core'

require 'schema_plus/indexes/active_record/base'
require 'schema_plus/indexes/active_record/connection_adapters/abstract_adapter'
require 'schema_plus/indexes/active_record/connection_adapters/index_definition'

require 'schema_plus/indexes/middleware/dumper'
require 'schema_plus/indexes/middleware/migration'
require 'schema_plus/indexes/middleware/model'
require 'schema_plus/indexes/middleware/schema'

SchemaMonkey.register SchemaPlus::Indexes
```

The details of ActiveRecord exentions and Middleware modules are described below.

## ActiveRecord Extensions

Here's a simple example of an extension to ActiveRecord:

```ruby
require 'schema_monkey'

module PracticalJoker
  module ActiveRecord
    module Base

       def save(*args)
         raise "April Fools!" if Time.now.yday == 91
         super
       end

       module ClassMethods
         def columns
           raise "Boo!" if Time.now.yday == 304
           super
         end
       end

      end
    end
  end
end

SchemaMonkey.register PracticalJoker
```

SchemaMonkey inserts each submodule of `MyClient::ActiveRecord` into the corresponding module of ActiveRecord, with `ClassMethods` inserted as class methods.

This works for arbitrary submodule paths, such as `MyClient::ActiveRecord::ConnectionAdapters::TableDefinition`.  SchemaMonkey will raise an error if the client defines a module that does not have a corresponding ActiveRecord module.

Notice that insertion is done using `Module.prepend`, so that client modules can override existing methods and use `super`.

### DBMS-specific insertion

If a client module's name includes one the dbms names `Mysql`, `PostgreSQL` or `SQLite3` (case insensitive), the insertion will only be performed if that's the dbms in use.  So, e.g. `MyClient::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter` will only be inserted if the app is using PostgreSQL.

Additionally, for ActiveRecord modules that are not inherently dbms-specific, you can use one of the dbms names (case insensitive) as a component in the client module's path to do dbms-specific insertion.   E.g.

```ruby
module MyClient
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3
        module TableDefinition
          #
          # SQLite3-specific enhancements to
          # ActiveRecord::ConnectionAdapters::TableDefinition
          #
        end
      end
    end
  end
end
```

The dbms name component can be anywhere in the module path after `MyClient::ActiveRecord`

### `insert` vs `prepend`


* By default, SchemaMonkey inserts a client module using `prepend`, and a client ClassMethods module using `singleton_class.prepend`. This allows overriding existing methods and using `super`.  On insertion, Ruby will of course call the module's `self.prepended` method, if one is defined.

* However, if the client module defines a module method `self.included` then SchemaMonkey will use `include` for a module and `singleton_class.include` for a ClassMethods module -- and Ruby will of course call that method.

Note that in the case of a ClassMethods module, when Ruby calls `self.prepended` or `self.included`, it will pass the singleton class.  For convience SchemaMonkey will also call `self.extended` if defined, passing it the ActiveRecord module itself, just as Ruby would if `extend` were used.

## Middleware Modules

SchemaMonkey provides a convention-based front end to using [modware](https://github.com/ronen/modware) middleware stacks.

SchemaMonkey uses Ruby modules to organize the stacks:  Each stack is contained in a submodule of `SchemaMonkey::Middleware`

### Defining a stack

Here's an example of defining a middleware stack:

```ruby
module MyClient
  module Middleware
    module Index
      module Exists
        Env = [:connection, :table_name, :column_name, :options, :result]
      end
    end
  end
end
```

This defines a stack available at `SchemaMonkey::Middleware::Index::Exists`.  You can use any module path you want for organizational convenience.  The const `Env` signals to SchemaMonkey to create a stack at that location; the environment object for the stack will have the listed fields. (Env actually can be an array of symbols or a Class, as per `Modware::Stack.new`.)

SchemaMonkey will raise an error if a stack had already been defined there.

The defined stack module has a module method `start` that delegates to `Modware::Stack.start`.  Here's an example of using the above stack as a wrapper around ActiveRecord's `index_exists?` method:

```ruby
module MyClient
  module ActiveRecord
    module ConnectionAdapters
      module SchemaStatements

        def index_exists?(table_name, column_name, options = {})
          SchemaMonkey::Middleware::Index::Exists.start(connection: self, table_name: table_name, column_name: column_name, options: options) { |env|
            env.result = super env.table_name, env.column_name, env.options
          }.result
        end

      end
    end
  end
end
```

This is a fairly typical idiom for wrapping behavior in a stack:

1. Pass `self` and the method arguments to the stack environment
2. Call the base implementation, passing it argument values from the environment (giving clients a chance to modify them in `before` or `around` methods)
3. Place the result in the environment (giving clients a chance to modify it in `after` or `around` methods
4. `start` returns the environment object -- the method returns the result that's stored in the environment

### Inserting Middleware in a stack

If an earlier client defined a stack, a later client can insert middleware into the stack:

```ruby
require 'my_client' # earlier client defines the stack

module UColumnImpliesUnique
  module Middlware
    module Index
      module Exists
        def before(env)
          env.options.reverse_merge!(unique: env.column_name.start_with? 'u')
        end
      end
    end
  end
end

SchemaMonkey.register(UColumnImpliesUnique)
```

SchemaMonkey uses the module `MyLaterClient::Middleware::Index::Exists` as [modware](https://github.com/ronen/modware) middleware for the corresponding stack.  The middleware module can define middleware methods `before`, `around`, `after`, or `implement` as per [modware](https://github.com/ronen/modware)

Note that the distinguishing feature between defining and using a stack is whether `Env` is defined.




## Compatibility

SchemaMonkey is tested on:

<!-- SCHEMA_DEV: MATRIX - begin -->
<!-- These lines are auto-generated by schema_dev based on schema_dev.yml -->
* ruby **2.3.1** with activerecord **4.2**, using **mysql2**, **sqlite3** or **postgresql**
* ruby **2.3.1** with activerecord **5.0**, using **mysql2**, **sqlite3** or **postgresql**
* ruby **2.3.1** with activerecord **5.1**, using **mysql2**, **sqlite3** or **postgresql**
* ruby **2.3.1** with activerecord **5.2**, using **mysql2**, **sqlite3** or **postgresql**

<!-- SCHEMA_DEV: MATRIX - end -->

## Release Notes
* 2.1.5 -- Remove dependency on its-it :(  #12
* 2.1.4 -- Loosen dependency to allow AR 5.0, and include it in the test matrix
* 2.1.3 -- Guard against multiple insertion of modules.
* 2.1.2 -- Insert self earlier; don't wait for connection adapter to be instantiated.  Fixes #6 re `db:schema:load`
* 2.1.1 -- Bug fix: don't choke if a module contains a BasicObject const
* 2.1.0 -- First version to support all of schema_plus's needs for the 1.8.7 -> 2.0 upgrade


## Development & Testing

Are you interested in contributing to schema_monkey?  Thanks!  Please follow
the standard protocol: fork, feature branch, develop, push, and issue pull request.

Some things to know about to help you develop and test:

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
* **schema_dev**:  SchemaMonkey uses [schema_dev](https://github.com/SchemaPlus/schema_dev) to
  facilitate running rspec tests on the matrix of ruby, activerecord, and database
  versions that the gem supports, both locally and on
  [travis-ci](http://travis-ci.org/SchemaPlus/schema_monkey)

  To to run rspec locally on the full matrix, do:

        $ schema_dev bundle install
        $ schema_dev rspec

  You can also run on just one configuration at a time;  For info, see `schema_dev --help` or the [schema_dev](https://github.com/SchemaPlus/schema_dev) README.

  The matrix of configurations is specified in `schema_dev.yml` in
  the project root.


<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - end -->
