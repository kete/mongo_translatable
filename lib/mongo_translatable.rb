# -*- coding: utf-8 -*-
require "active_record"
require "mongo_mapper"
module MongoTranslatable #:nodoc:
  # MongoTranslatable is for taking advantage of MongoDB for storing translations
  # of ActiveRecord models. Here is how it works in practice:
  #   class Item < ActiveRecord::Base
  #     mongo_translate :label
  #   end
  #
  #   I18n.locale = :en
  # 
  #   item = Item.create(:label => "a label")
  #   p item.locale
  #   "en"
  #
  #   item = Item.find(1)
  #   p item.label
  #   "a label"
  #
  #   item.translate(:label => "etiketissä", :locale => :fi)
  ## or you could have set I18n.locale = :fi in calling env and dropped locale from args
  #
  #   I18n.locale = :fi
  #   item = Item.find(1)
  #   p item.label
  #   "etiketissä"
  #   p item.locale
  #   "fi"
  #
  # If 
  # The general approach is inspired by this code in globalize2:
  # http://github.com/joshmh/globalize2/blob/master/lib/globalize/active_record.rb
  # grab what the normal finder would return
  # and look up corresponding translated version of the objects in question
  # swap in corresponding translated attributes of object
  # creates TranslatableClass::Translation when the declaration method is defined
  # ala acts_as_versioned VersionedClass::Version
  # every translatable class gets their own Translation class under it
  # 
  # TODO: translations aren't real associations
  # and the translations method is thus not chainable as you would expect
  # currently investigating adding a plugin for mongo_mapper that will do associations declaired
  # from activerecord models
  # in the meantime, you will like want to use the "translation_for(locale)" method
  module Translated
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      def mongo_translate(*args)
        # don't allow multiple calls
        return if self.included_modules.include?(MongoTranslatable::Translated::InstanceMethods)
        
        send :include, MongoTranslatable::Translated::InstanceMethods

        options = args.last.is_a?(Hash) ? args.pop : Hash.new
        translatable_attributes = args.is_a?(Array) ? args : [args]

        cattr_accessor :translatable_attributes, :as_foreign_key_sym

        # expects a single attribute name symbol or array of attribute names as symbols
        self.translatable_attributes = translatable_attributes
        self.as_foreign_key_sym = self.name.foreign_key.to_sym

        before_save :set_locale_if_necessary

        original_class = self

        # create the dynamic translation model
        const_set("Translation", Class.new).class_eval do
          include MongoMapper::Document
          
          @@translatable_class = original_class

          original_class.translatable_attributes.each do |translatable_attribute|
            key translatable_attribute, String
          end

          key :locale, String, :required => true
          
          before_save :locale_to_string

          # TODO: add validation for locale unique to translatable_class.as_foreign_key_sym scope
          # not implemented in mongo mapper yet

          def translatable
            @@translatable_class.find(self.send(@@translatable_class.as_foreign_key_sym))
          end
          
          protected
          # always store string version of locale (rather than symbol)
          def locale_to_string
            self.locale = self.locale.to_s
          end
        end

        class_eval do
          # override find, this is called by all the dynamic finders
          # it isn't called by find_by_sql though (may be other exceptions)
          def self.find(*args)
            # get the standard results from find
            # this will throw a RecordNotFound before executing our code
            # if that is the response
            results = super(*args)
            
            # handle single record
            if results.is_a?(self)
              result = results

              # only look up translation if the required locale is not the default for the record
              if result.present? && result.locale != I18n.locale.to_s
                # look up translation and swap in its attributes for result
                translated = result.translation_for(I18n.locale)
                if translated.present?
                  self.translatable_attributes.each do |translated_attribute|
                    result.send(translated_attribute.to_s + "=", translated.attributes[translated_attribute])
                  end
                  result.locale = translated.locale
                end
              end

              results = result
            else
              # handle multiple records
              # do second query of translations
              # if item locale is different than current locale
              # swap in attributse from translation for item that is current locale

              # rather than rerun the full query, simply get ids and add locale
              result_ids = results.collect { |result| result.id }  

              conditions = {:locale => I18n.locale.to_s}
              conditions[as_foreign_key_sym] = result_ids

              translations = self::Translation.all(conditions)

              translated_results = results
              index = 0
              results.each do |result|
                unless result.locale == I18n.locale.to_s
                  matching_translation = translations.select { |t| t[as_foreign_key_sym] == result.id }.first
                  
                  if matching_translation
                    translatable_attributes.each do |key|
                      result.send(key.to_s + "=", matching_translation.attributes[key])
                    end

                    result.locale = I18n.locale.to_s

                    translated_results[index] = result
                  end
                end
                index += 1
              end
              results = translated_results
            end
          end
        end
      end
    end
    module InstanceMethods
      # TODO: in an ActiveRecord backed verions
      # this functionality would have to be recreated
      # many :translations

      def translations
        self.class::Translation.all(self.class.as_foreign_key_sym => id)
      end

      # assumes unique locale
      def translation_for(locale)
        self.class::Translation.first(self.class.as_foreign_key_sym => id, :locale => locale)
      end

      # this will create a new translation
      # with either passed in options
      # note that we don't save the changes to self
      # only the new translation
      def translate(options = {})
        translation_locale = options[:locale].present? ? options[:locale] : I18n.locale
        should_save = options[:save].present? ? options[:save] : true

        @translation = self.class::Translation.new

        # work through self and replace attributes
        # with the passed in translations for defined translatable_attributes
        translated_attributes = Hash.new
        self.class.translatable_attributes.each do |translated_attribute|
          translated_value = options[translated_attribute]

          next unless translated_value

          translated_attributes[translated_attribute] = translated_value
        end

        # only create a translation if actual translation was done
        # if changed?
        unless translated_attributes.blank?
          translated_attributes[:locale] = translation_locale
          translated_attributes[self.class.as_foreign_key_sym] = id

          @translation = self.class::Translation.new(translated_attributes)
          @translation.save if should_save
        end
        @translation
      end

      protected
      # always store string version of locale (rather than symbol)
      # if none is specified, use environment's setting
      def set_locale_if_necessary
        self.locale = self.locale.present? ? self.locale : I18n.locale
        self.locale = self.locale.to_s
      end
    end
  end
end

ActiveRecord::Base.class_eval { include MongoTranslatable::Translated }
