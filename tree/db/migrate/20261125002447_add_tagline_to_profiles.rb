class AddTaglineToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :tagline_pt, :string
    add_column :profiles, :tagline_en, :string
  end
end
