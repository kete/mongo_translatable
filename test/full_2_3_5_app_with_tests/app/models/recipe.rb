class Recipe < ActiveRecord::Base
  # mongo_translate :name, :ingredients, :steps
  mongo_translate :name, [:ingredients, Array], [:steps, Array]

  def steps=(value)
    super(YAML.dump(value))
  end

  def ingredients=(value)
    super(YAML.dump(value))
  end

  def steps
    YAML.load(super)
  end

  def ingredients
    YAML.load(super)
  end

end
