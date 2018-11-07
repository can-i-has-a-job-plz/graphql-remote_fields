# GraphQL::RemoteFields

Plugin for [graphql-ruby](https://github.com/rmosolgo/graphql-ruby) which adds support for [schema stiching](https://www.prisma.io/blog/how-do-graphql-remote-schemas-work-7118237c89d7/)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-remote_fields', github: 'can-i-has-a-job-plz/graphql-remote_fields'
```

And then execute:

    $ bundle

## Usage

```ruby
  module Types
    module Types
      class AuthorType < GraphQL::Schema::Object
        field :id, ID, null: false
        field :name, String, null: false
      end

      class BookType < GraphQL::Schema::Object
        field :id, ID, null: false
        field :name, String, null: false
      end

      class CitationType < GraphQL::Schema::Object
        field :id, ID, null: false
        field :content, String, null: false
      end
    end

    class Query < GraphQL::Schema::Object
      # Enable plugin
      include GraphQL::RemoteFields

      # Set default remote_resolved, can be omitted
      remote_resolver StubResolver

      field :authors, [Types::AuthorType], null: false
      # Use default remote resolving for fetching books
      field :books, [Types::BookType], null: false, remote: true
      # Use custom remote_resolver for citations. `remote: true` can be omitted
      # if `remote_resolver` is set
      field :citations, [Types::CitationType],
            null: false, remote_resolver: StubCitationsResolver
    end
  end
end

class Schema < GraphQL::Schema
  query GraphqlApi::Types::Query
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the rubocop & tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/can-i-has-a-job-plz/graphql-remote_fields.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
