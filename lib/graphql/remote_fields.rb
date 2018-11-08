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

    # rubocop:disable Metrics/ParameterLists
    def initialize(*args, remote: nil, remote_resolver: nil, remote_type: nil,
                   remote_fieldmap: nil, **kwargs, &block)
      @remote_resolver = remote_resolver
      @remote_resolver ||= (remote && kwargs.fetch(:owner).remote_resolver_obj)

      raise 'remote_resolver is not set' if remote && @remote_resolver.nil?

      @remote_type = remote_type
      @remote_fieldmap = remote_fieldmap

      super(*args, **kwargs, &block)
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/MethodLength
    def resolve_field(obj, args, ctx)
      return super unless @remote_resolver

      resp = @remote_resolver.resolve_remote_field(
        remote_query(ctx).to_query_string(
          printer: VariableExpander.new(args)
        ).strip,
        ctx
      )

      return resp unless @remote_fieldmap

      resp.each_with_object({}) do |(k, v), h|
        # We can invert hash in initialize & use it instead of #key, but I'm not
        # sure that it's performance-critical
        h[@remote_fieldmap.value?(k) ? @remote_fieldmap.key(k) : k] = v
      end
    end

    private

    def remote_query(ctx)
      selection = ctx.ast_node
      selection.name = @remote_type if @remote_type
      if @remote_fieldmap
        selection.selections.each do |sel|
          next unless @remote_fieldmap.key?(sel.name)

          sel.name = @remote_fieldmap.fetch(sel.name)
        end
      end
      Language::Nodes::OperationDefinition.new(
        name: 'query',
        selections: [selection]
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
