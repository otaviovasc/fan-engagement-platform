class AddYoutubeFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :youtube_id, :string
    add_column :users, :youtube_access_token, :string
    add_column :users, :youtube_refresh_token, :string
  end
end
