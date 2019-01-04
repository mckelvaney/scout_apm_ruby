module ScoutApm
  module FrameworkIntegrations
    class Padrino
      def name
        :padrino
      end

      def human_name
        "Padrino"
      end

      def version
        ::Padrino::VERSION
      end

      def present?
        defined?(::Padrino)
      end

      def application_name
        possible = ObjectSpace.each_object(Class).select { |klass| klass < ::Padrino::Application } - [::Padrino::Application]
        if possible.length == 1
          possible.first.name.split('::').first
        else
          "Padrino"
        end
      rescue => e
        ScoutApm::Agent.instance.context.logger.debug "Failed getting Sinatra Application Name: #{e.message}\n#{e.backtrace.join("\n\t")}"
        "Padrino"
      end

      def env
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      end

      # TODO: Figure out how to detect this smarter
      def database_engine
        return @database_engine if @database_engine
        default = :postgres

        @database_engine = if defined?(ActiveRecord::Base)
          adapter = raw_database_adapter # can be nil

          case adapter.to_s
          when "postgres"   then :postgres
          when "postgresql" then :postgres
          when "postgis"    then :postgres
          when "sqlite3"    then :sqlite
          when "sqlite"     then :sqlite
          when "mysql"      then :mysql
          when "mysql2"     then :mysql
          else default
          end
        else
          # TODO: Figure out how to detect outside of Rails context. (sequel, ROM, etc)
          return :mongoid if defined?(::Mongoid)
          default
        end
      end

      def raw_database_adapter
        adapter = ActiveRecord::Base.connection_config[:adapter].to_s rescue nil

        if adapter.nil?
          adapter = ActiveRecord::Base.configurations[env]["adapter"]
        end

        return adapter
      rescue # this would throw an exception if ActiveRecord::Base is defined but no configuration exists.
        nil
      end
    end
  end
end
