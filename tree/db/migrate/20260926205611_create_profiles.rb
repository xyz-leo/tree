class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.string :name, null: false
      t.string :handle, null: false
      t.text :bio_pt
      t.text :bio_en

      t.timestamps
    end
  end
end
