class MoveBodyToActionText < ActiveRecord::Migration[7.0]
  def change
    BlogPost.all.find_each do |e| 
      e.update(content: e.body)
    end

    remove_column :blog_posts, :body
  end
end
