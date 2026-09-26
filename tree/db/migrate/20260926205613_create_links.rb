class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.references :link_group, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      t.string :hint_pt
      t.string :hint_en
      t.integer :position, null: false

      t.timestamps
    end
  end
end
