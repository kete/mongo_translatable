ActiveRecord::Schema.define(:version => 0) do
  create_table :items, :force => true do |t|
    t.string :label, :null => false
    t.string :value, :locale
    
    t.timestamps
  end
end
