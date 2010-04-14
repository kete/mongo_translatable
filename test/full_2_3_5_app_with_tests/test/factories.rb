Factory.define :item do |f|
  f.sequence(:label) { |n| "a label#{n}"}
end

