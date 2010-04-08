require 'rubygems'
require 'active_support'
require 'action_controller'
require 'action_controller/test_case'
require 'action_view'
require 'test_help'
require 'shoulda'


require File.dirname(__FILE__) + '/../rails/init.rb'

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
  ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + "/schema.rb")
  require File.dirname(__FILE__) + '/../rails/init.rb'
end

require 'factory_girl'

require File.expand_path(File.dirname(__FILE__) + "/factories")

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

class ActiveSupport::TestCase

  # MongoDB teardown per test case
  # Drop all columns after each test case.
  def teardown
    # because we are outside of rails proper
    # the activerecord model instances weren't being wiped from the db
    # doing it by hand here, but may want to change this in the future
    Item.destroy_all

    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end

  # Make sure that each test case has a teardown
  # method to clear the db after each test.
  def inherited(base)
    base.define_method teardown do
      super
    end
  end
end

MongoMapper.database = 'test'

# testing schema set up and model pulled from rails guide at http://guides.rubyonrails.org/plugins.html#test-setup
load_schema

# only one simple model for testing at the moment
# may split this to separate file late if more complexity required
class Item < ActiveRecord::Base
  mongo_translate :label
end
