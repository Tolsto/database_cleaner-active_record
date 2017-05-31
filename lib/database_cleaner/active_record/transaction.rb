require 'database_cleaner/active_record/base'
require 'database_cleaner/generic/transaction'

module DatabaseCleaner::ActiveRecord
  class Transaction
    include ::DatabaseCleaner::ActiveRecord::Base
    include ::DatabaseCleaner::Generic::Transaction

    def start
      # Hack to make sure that the connection is properly setup for
      # the clean code.
      connection_class.connection.transaction{ }

      if connection_class.connection.respond_to?(:begin_transaction)
        connection_class.connection.begin_transaction :joinable => false
      else
        connection_class.connection.begin_db_transaction
      end
    end


    def clean
      connection_class.connection_pool.connections.each do |connection|
        next unless connection.open_transactions > 0

        if connection.respond_to?(:rollback_transaction)
          connection.rollback_transaction
        else
          connection.rollback_db_transaction
        end

        # The below is for handling after_commit hooks.. see https://github.com/bmabey/database_cleaner/issues/99
        if connection.respond_to?(:rollback_transaction_records, true)
          connection.send(:rollback_transaction_records, true)
        end
      end
    end
  end
end
