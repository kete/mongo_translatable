# -*- coding: utf-8 -*-
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'rubygems'
require 'shoulda'
require 'factory_girl'
require "webrat"

require File.expand_path(File.dirname(__FILE__) + "/factories")

Webrat.configure do |config|
  config.mode = :rails
end

LOCALE_LABELS = { :en => "a label",
  :ar => "تسمية",
  :fi => "etiketissä",
  :fr => "une étiquette",
  :zh => "標籤"}

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  # self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  # self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
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

def translate_item_for_locales(item, locales)
  locales = [locales] unless locales.is_a?(Array)
  locales.each do |locale|
    I18n.locale = locale
    item.translate(:label => LOCALE_LABELS[locale]).save
  end
end

