# frozen_string_literal: true

RSpec.describe GraphQL::RemoteFields do
  let(:base_type) do
    Class.new(GraphQL::Schema::Object) do
      include GraphQL::RemoteFields
    end
  end
  let(:resolver) { Object.new }
  let(:variables) { {} }
  let(:execute_query) do
    -> { Schema.execute(query_string, variables: variables).to_h }
  end

  it 'has a version number' do
    expect(GraphQL::RemoteFields::VERSION).not_to be nil
  end

  context '.remote_resolver' do
    context 'when resolver respond_to?(:resolve_remote_field)' do
      before do
        def resolver.resolve_remote_field; end
      end
      it 'should not raise error' do
        expect { base_type.remote_resolver resolver }.not_to raise_error
      end

      context '.remote_resolver_obj' do
        before { base_type.remote_resolver resolver }

        context 'on base type' do
          it 'should return passed resolver' do
            expect(base_type.remote_resolver_obj).to equal(resolver)
          end
        end

        context 'on subtype' do
          let(:sub_type) do
            Class.new(base_type) do
              field :id, GraphQL::Schema::Object::ID, null: false
            end
          end
          it 'should return passed resolver' do
            expect(sub_type.remote_resolver_obj).to equal(resolver)
          end
        end
      end
    end

    context 'when resolver !respond_to?(:resolve_remote_field)' do
      let(:error_msg) do
        'Remote resolver should respond to :resolve_remote_field'
      end

      it do
        expect { base_type.remote_resolver resolver }
          .to raise_error(ArgumentError).with_message(error_msg)
      end
    end
  end

  context 'field w/o remote' do
    let(:base_type) { Class.new(GraphQL::Schema::Object) }
    let(:query) do
      Class.new(base_type) do
        field :id, GraphQL::Schema::Object::ID, null: false
      end
    end

    let(:query_string) do
      <<~QUERY
        {
          authors {
            id,
            name
          }
        }
      QUERY
    end
    let(:expected) do
      {
        'data' => include(
          'authors' => match_array(GraphqlApi::AUTHORS)
        )
      }
    end

    it 'should not raise if remote_resolver is not set' do
      expect { query }.not_to raise_error
    end

    it 'should return expected authors' do
      expect(execute_query.call).to match(expected)
    end
  end

  context 'field with remote: true' do
    let(:query) do
      Class.new(base_type) do
        field :id, GraphQL::Schema::Object::ID, null: false, remote: true
      end
    end

    context 'when remote_resolver is set globally' do
      before do
        def resolver.resolve_remote_field(query, ctx); end
        base_type.remote_resolver resolver
      end

      it { expect { query }.not_to raise_error }

      context 'query execution' do
        let(:variables) { { 'bookId' => 2 } }
        let(:query_string) do
          <<~QUERY
            query getBook($bookId: ID!){
              authors {
                id,
                name
              },
              books {
                id,
                name
              },
              book(id: $bookId) {
                id,
                name
              }
            }
          QUERY
        end
        let(:expected_books_query) do
          <<~QUERY.strip
            query {
              books {
                id
                name
              }
            }
          QUERY
        end
        let(:expected_book_query) do
          <<~QUERY.strip
            query {
              book(id: 2) {
                id
                name
              }
            }
          QUERY
        end
        let(:expected) do
          {
            'data' => include(
              'authors' => match_array(GraphqlApi::AUTHORS),
              'books' => match_array(GraphqlApi::BOOKS),
              'book' => GraphqlApi::BOOKS[1]
            )
          }
        end

        before do
          expect(GraphqlApi::StubResolver)
            .to receive(:resolve_remote_field)
            .with(
              expected_books_query,
              instance_of(GraphQL::Query::Context::FieldResolutionContext)
            )
            .once
            .and_call_original
          expect(GraphqlApi::StubResolver)
            .to receive(:resolve_remote_field)
            .with(
              expected_book_query,
              instance_of(GraphQL::Query::Context::FieldResolutionContext)
            )
            .once
            .and_call_original
        end

        it 'should return expected authors and books' do
          expect(execute_query.call).to match(expected)
        end
      end
    end

    context 'when remote_resolver is set locally' do
      let(:query) do
        resolver = resolver
        Class.new(base_type) do
          field :id, GraphQL::Schema::Object::ID, null: false,
                                                  remote_resolver: resolver
        end
      end
      before do
        def resolver.resolve_remote_field(query, ctx); end
      end

      it { expect { query }.not_to raise_error }

      context 'query execution' do
        let(:query_string) do
          <<~QUERY
            query {
              authors {
                id,
                name
              },
              citations {
                id,
                content
              }
            }
          QUERY
        end
        let(:expected_citations_query) do
          <<~QUERY.strip
            query {
              citations {
                id
                content
              }
            }
          QUERY
        end
        let(:expected) do
          {
            'data' => include(
              'authors' => match_array(GraphqlApi::AUTHORS),
              'citations' => match_array(GraphqlApi::CITATIONS)
            )
          }
        end

        before do
          expect(GraphqlApi::StubCitationsResolver)
            .to receive(:resolve_remote_field)
            .with(
              expected_citations_query,
              instance_of(GraphQL::Query::Context::FieldResolutionContext)
            )
            .once
            .and_call_original
        end

        it 'should return expected authors and citations' do
          expect(execute_query.call).to match(expected)
        end
      end
    end

    context 'when remote_resolver is not set' do
      it do
        expect { query }.to raise_error(RuntimeError)
          .with_message('remote_resolver is not set')
      end
    end
  end
end
