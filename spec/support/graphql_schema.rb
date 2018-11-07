# frozen_string_literal: true

require 'graphql'
require 'graphql/remote_fields'

module GraphqlApi
  AUTHORS = [{ 'id' => '1', 'name' => 'Victor Pelevin' },
             { 'id' => '2', 'name' => 'Vladimir Sorokin' }].freeze

  BOOKS = [{ 'id' => '1', 'name' => 'Generation "П"' },
           { 'id' => '2', 'name' => 'Blue Salo' }].freeze

  class StubResolver
    def self.resolve_remote_field(_query, context)
      case context.ast_node.name
      when 'books' then BOOKS
      when 'book' then BOOKS[1]
      else raise
      end
    end
  end

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
    end

    class Query < GraphQL::Schema::Object
      include GraphQL::RemoteFields

      remote_resolver StubResolver

      field :authors, [Types::AuthorType], null: false
      field :books, [Types::BookType], null: false, remote: true
      field :book, Types::BookType, null: false, remote: true do
        argument :id, ID, required: true
      end

      def authors
        AUTHORS
      end
    end
  end
end

class Schema < GraphQL::Schema
  query GraphqlApi::Types::Query
end
