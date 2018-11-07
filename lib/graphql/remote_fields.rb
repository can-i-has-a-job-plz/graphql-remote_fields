# frozen_string_literal: true

require 'graphql'
require 'graphql/remote_fields/version'

module GraphQL
  module RemoteFields # :nodoc:
    module ClassMethods # :nodoc:
      def remote_resolver(resolver)
        unless resolver.respond_to?(:resolve_remote_field)
          raise ArgumentError,
                'Remote resolver should respond to :resolve_remote_field'
        end

        @remote_resolver = resolver
      end

      def remote_resolver_obj
        if defined?(@remote_resolver)
          @remote_resolver
        elsif superclass.respond_to?(:remote_resolver_obj)
          superclass.remote_resolver_obj
        end
      end
    end

    class VariableExpander < GraphQL::Language::Printer # :nodoc:
      def initialize(args)
        @args = args
      end

      def print_argument(arg)
        "#{arg.name}: #{@args[arg.name]}"
      end
    end

    def self.included(klass)
      klass.field_class.prepend(self)
      klass.extend ClassMethods
    end

    def initialize(*args, remote: nil, **kwargs, &block)
      if remote && !kwargs.fetch(:owner).remote_resolver_obj
        raise 'remote_resolver is not set'
      end

      @remote = remote

      super(*args, **kwargs, &block)
    end

    def resolve_field(obj, args, ctx)
      return super unless @remote

      obj.class.remote_resolver_obj.resolve_remote_field(
        remote_query(ctx).to_query_string(
          printer: VariableExpander.new(args)
        ).strip,
        ctx
      )
    end

    private

    def remote_query(ctx)
      Language::Nodes::OperationDefinition.new(
        name: 'query',
        selections: [ctx.ast_node]
      )
    end
  end
end
