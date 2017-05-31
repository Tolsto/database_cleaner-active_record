require 'spec_helper'
require 'active_record'
if ActiveRecord::VERSION::MAJOR >= 5
  require 'support/active_record/mysql2_setup'
else
  require 'support/active_record/mysql_setup'
  require 'support/active_record/mysql2_setup'
end
require 'database_cleaner/active_record/truncation'
require 'database_cleaner/active_record/truncation/shared_fast_truncation'

module ActiveRecord
  module ConnectionAdapters
    ADAPTERS =
      if ActiveRecord::VERSION::MAJOR < 5
        [ "mysql", "mysql2" ]
      else
        [ "mysql2" ]
      end

    describe do
      ADAPTERS.each do |adapter|
        context "using the #{adapter} adapter" do
          before(:all) { send(:"active_record_#{adapter}_setup") }

          let(:connection) { send(:"active_record_#{adapter}_connection") }

          describe "#truncate_table" do
            it "should truncate the table" do
              2.times { User.create }

              connection.truncate_table('users')
              User.count.should eq 0
            end

            it "should reset AUTO_INCREMENT index of table" do
              2.times { User.create }
              User.delete_all

              connection.truncate_table('users')

              User.create.id.should eq 1
            end
          end

          it_behaves_like "an adapter with pre-count truncation" do
            let(:connection) { send(:"active_record_#{adapter}_connection") }
          end
        end
      end
    end
  end
end
