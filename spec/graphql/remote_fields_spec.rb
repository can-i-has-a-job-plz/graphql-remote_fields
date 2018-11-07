# frozen_string_literal: true

RSpec.describe GraphQL::RemoteFields do
  let(:base_type) do
    Class.new(GraphQL::Schema::Object) do
      include GraphQL::RemoteFields
    end
  end
  let(:resolver) { Object.new }

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
      expect(Schema.execute(query_string).to_h).to match(expected)
    end
  end

  context 'field with remote: true' do
    let(:query) do
      Class.new(base_type) do
        field :id, GraphQL::Schema::Object::ID, null: false, remote: true
      end
    end

    context 'when remote_resolver is set' do
      before do
        def resolver.resolve_remote_field(query, ctx); end
        base_type.remote_resolver resolver
      end

      it { expect { query }.not_to raise_error }
    end

    context 'when remote_resolver is not set' do
      it do
        expect { query }.to raise_error(RuntimeError)
          .with_message('remote_resolver is not set')
      end
    end
  end
end
