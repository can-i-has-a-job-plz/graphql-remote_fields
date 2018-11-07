# frozen_string_literal: true

require 'graphql'
require 'graphql/remote_fields'

module GraphqlApi
  AUTHORS = [{ 'id' => '1', 'name' => 'Victor Pelevin' },
             { 'id' => '2', 'name' => 'Vladimir Sorokin' }].freeze

  module Types
    module Types
      class AuthorType < GraphQL::Schema::Object
        field :id, ID, null: false
        field :name, String, null: false
      end
    end

    class Query < GraphQL::Schema::Object
      field :authors, [Types::AuthorType], null: false

      def authors
        AUTHORS
      end
    end
  end
end

class Schema < GraphQL::Schema
  query GraphqlApi::Types::Query
end
