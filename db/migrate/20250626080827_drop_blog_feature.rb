class DropBlogFeature < ActiveRecord::Migration[8.0]
  def change
    # Drop blog_posts table if it exists
    drop_table :blog_posts, if_exists: true do |t|
      t.string :title
      t.datetime :published_at
      t.datetime :created_at, precision: 6, null: false
      t.datetime :updated_at, precision: 6, null: false
    end
    
    # Drop action_text tables if they exist (since they were only used by blog posts)
    drop_table :action_text_rich_texts, if_exists: true do |t|
      t.string :name, null: false
      t.text :body, size: :long
      t.references :record, null: false, polymorphic: true, index: false
      t.datetime :created_at, precision: 6, null: false
      t.datetime :updated_at, precision: 6, null: false
      t.index [:record_type, :record_id, :name], name: "index_action_text_rich_texts_uniqueness", unique: true
    end
    
    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_attachments, if_exists: true  
    drop_table :active_storage_blobs, if_exists: true
  end
end
