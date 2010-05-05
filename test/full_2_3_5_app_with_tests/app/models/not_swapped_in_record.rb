class NotSwappedInRecord < ActiveRecord::Base
  mongo_translate :name, :redefine_find => false
end
