Factory.define :item do |f|
  f.sequence(:label) { |n| "a label#{n}"}
  f.sequence(:description) { |n| "a description#{n}"}
end

Factory.define :not_swapped_in_record do |r|
  r.sequence(:name) { |n| "a name#{n}"}
end

Factory.define :person do |p|
  p.sequence(:name) { |n| "a name#{n}"}
end
