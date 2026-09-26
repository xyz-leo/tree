class CreateLinkGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :link_groups do |t|
      t.string :label_pt, null: false
      t.string :label_en
      t.integer :position, null: false

      t.timestamps
    end
  end
end
