class CreateStaffAbsences < ActiveRecord::Migration[7.1]
  def change
    create_table :staff_absences do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :absence_type, null: false
      t.time :start_time
      t.time :end_time
      t.string :note

      t.timestamps
    end

    add_index :staff_absences, %i[user_id date]
  end
end
