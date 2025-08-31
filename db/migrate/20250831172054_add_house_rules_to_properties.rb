class AddHouseRulesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :check_in_time, :string, default: "3:00 PM"
    add_column :properties, :check_out_time, :string, default: "11:00 AM"
    add_column :properties, :max_guests, :integer, default: 4
    add_column :properties, :smoking_allowed, :boolean, default: false
    add_column :properties, :parties_allowed, :boolean, default: false
    add_column :properties, :quiet_hours, :string, default: "10:00 PM - 8:00 AM"
    add_column :properties, :additional_rules, :text
  end
end
