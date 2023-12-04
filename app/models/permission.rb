class Permission < ApplicationRecord
  has_and_belongs_to_many :roles, join_table: "roles_permissions"
end
