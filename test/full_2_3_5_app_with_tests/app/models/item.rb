class Item < ActiveRecord::Base
  belongs_to :person
  has_many :comments
  mongo_translate :label, :description
end
