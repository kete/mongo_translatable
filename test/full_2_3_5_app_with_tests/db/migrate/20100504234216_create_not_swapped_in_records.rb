class CreateNotSwappedInRecords < ActiveRecord::Migration
  def self.up
    create_table :not_swapped_in_records do |t|
      t.string :name, :null => false
      t.string :locale, :original_locale

      t.timestamps
    end

  end

  def self.down
    drop_table :not_swapped_in_records
  end
end
