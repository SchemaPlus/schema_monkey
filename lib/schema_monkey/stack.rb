module SchemaMonkey
  module Stack
    module StartMethod
      attr_reader :stack

      def start(env, &block)
        stack.start(env, &block)
      end

      private

      def stack=(stack)
        @stack = stack
      end
    end
  end
end
