class CreateCompanies < ActiveRecord::Migration[6.1]
  def change
    create_table :companies do |t|
      t.string :title
      t.string :company_number
      t.string :company_status
      t.string :description
      t.string :address_snippet
      t.string :address
      t.string :company_type
      t.date :date_of_creation

      t.timestamps
    end
  end
end
