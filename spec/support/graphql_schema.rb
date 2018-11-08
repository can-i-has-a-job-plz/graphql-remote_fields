# frozen_string_literal: true

require 'graphql'
require 'graphql/remote_fields'

module GraphqlApi
  AUTHORS = [{ 'id' => '1', 'name' => 'Victor Pelevin' },
             { 'id' => '2', 'name' => 'Vladimir Sorokin' }].freeze

  BOOKS = [{ 'id' => '1', 'name' => 'Generation "П"' },
           { 'id' => '2', 'name' => 'Blue Salo' }].freeze

  CITATIONS = [{ 'id' => '1',
                 'content' => 'Агитпроп бессмертен. Меняются только слова.' },
               { 'id' => '2', 'content' => 'Ясауууух пашооооо!!!' }].freeze

  NEW_CITATIONS = [{ 'id' => '1',
                     'text' => 'Агитпроп бессмертен. Меняются только слова.' },
                   { 'id' => '2', 'text' => 'Ясауууух пашооооо!!!' }].freeze

  class StubResolver
    def self.resolve_remote_field(_query, context)
      case context.ast_node.name
      when 'books' then BOOKS
      when 'book' then BOOKS[1]
      else raise
      end
    end
  end

  class StubCitationsResolver
    def self.resolve_remote_field(_query, context)
      case context.ast_node.name
      when 'citations' then CITATIONS
      when 'otherType' then NEW_CITATIONS.first
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

      class CitationType < GraphQL::Schema::Object
        field :id, ID, null: false
        field :content, String, null: false
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
      field :citations, [Types::CitationType],
            null: false, remote_resolver: StubCitationsResolver
      field :citation, Types::CitationType,
            null: false, remote_resolver: StubCitationsResolver,
            remote_type: 'otherType',
            remote_fieldmap: { 'content' => 'text' }.freeze

      def authors
        AUTHORS
      end
    end
  end
end

class Schema < GraphQL::Schema
  query GraphqlApi::Types::Query
end
