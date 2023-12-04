class RolesPermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :roles_permissions, id: false do |t|
      t.references :role, null: false
      t.references :permission, null: false
    end
    add_index(:roles_permissions, [ :permission_id, :role_id ], unique: true)
  end
end
