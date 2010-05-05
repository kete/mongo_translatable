Factory.define :item do |f|
  f.sequence(:label) { |n| "a label#{n}"}
end

Factory.define :not_swapped_in_record do |r|
  r.sequence(:name) { |n| "a name#{n}"}
end
