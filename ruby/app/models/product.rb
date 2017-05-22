# Copyright 2015, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START product_class]
require "google/cloud/datastore"

class Product

  attr_accessor :id, :name, :downcase_name, :image_url

  # Return a Google::Cloud::Datastore::Dataset for the configured dataset.
  # The dataset is used to create, read, update, and delete entity objects.
  def self.dataset
    @dataset ||= Google::Cloud::Datastore.new(
        project: Rails.application.config.
            database_configuration[Rails.env]["dataset_id"]
    )
  end

  # [END product_class]

  # [START query]
  # Query Product entities from Cloud Datastore.
  #
  # returns an array of Product query results and a cursor
  # that can be used to query for additional results.
  def self.query options = {}
    query = Google::Cloud::Datastore::Query.new
    query.kind "Product"
    query.limit options[:limit] if options[:limit]
    query.cursor options[:cursor] if options[:cursor]

    results = dataset.run query
    products = results.map { |entity| Product.from_entity entity }

    if options[:limit] && results.size == options[:limit]
      next_cursor = results.cursor
    end

    return products, next_cursor
  end

  # [END query]

  # [START from_entity]
  def self.from_entity entity
    product = Product.new
    product.id = entity.key.id
    entity.properties.to_hash.each do |name, value|
      product.send "#{name}=", value if product.respond_to? "#{name}="
    end
    product
  end

  # [END from_entity]

  # [START find]
  # Lookup Product by ID.  Returns Product or nil.
  def self.find id
    query = Google::Cloud::Datastore::Key.new "Product", id.to_i
    entities = dataset.lookup query

    from_entity entities.first if entities.any?
  end

  # [END find]

  # Add Active Model support.
  # Provides constructor that takes a Hash of attribute values.
  include ActiveModel::Model

  # [START save]
  # Save the product to Datastore.
  # @return true if valid and saved successfully, otherwise false.
  def save
    if valid?
      entity = to_entity
      Product.dataset.save entity
      self.id = entity.key.id
      true
    else
      false
    end
  end

  # [END save]

  # [START to_entity]
  # ...
  def to_entity
    entity = Google::Cloud::Datastore::Entity.new
    entity.key = Google::Cloud::Datastore::Key.new "Product", id
    entity["name"] = name
    entity["downcase_name"] = downcase_name
    entity["image_url"] = image_url
    entity
  end

  # [END to_entity]

  # [START validations]
  # Add Active Model validation support to Product class.
  include ActiveModel::Validations

  validates :name, :downcase_name, :image_url, presence: true
  # [END validations]

  # [START update]
  # Set attribute values from provided Hash and save to Datastore.
  def update attributes
    attributes.each do |name, value|
      send "#{name}=", value if respond_to? "#{name}="
    end
    save
  end

  # [END update]

  # [START destroy]
  def destroy
    Product.dataset.delete Google::Cloud::Datastore::Key.new "Product", id
  end

  # [END destroy]

  ##################

  def persisted?
    id.present?
  end

  def self.import
    file = File.read('../products.json')
    data = JSON.parse(file)

    data.each do |key, value|

      p = Product.new
      p.name = key['name']
      p.downcase_name = key['name'].downcase
      p.image_url = key['image']

        begin
          p.save
        rescue Exception => e
          print "Error Saving... #{p.to_json}."
          puts e.backtrace.inspect
        end


    end

    nil
  end

  def self.autosearch(term)
    q = Product.dataset.query("Product").
        where("downcase_name", ">=", term).
        where("downcase_name", "<", term + "\ufffd").
        order("downcase_name", :asc).
        limit(5)

    results = Product.dataset.run q
    products = results.map do |entity|
      p = Product.from_entity entity
    end

    products

  end

end
