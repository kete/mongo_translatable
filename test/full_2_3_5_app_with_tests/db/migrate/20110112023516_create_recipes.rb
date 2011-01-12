class CreateRecipes < ActiveRecord::Migration
  def self.up
    create_table :recipes do |t|
      t.string :name, :locale, :original_locale, :null => false
      t.text :ingredients, :steps, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :recipes
  end
end
