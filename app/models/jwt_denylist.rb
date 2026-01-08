class JwtDenylist < ApplicationRecord
  self.table_name = 'jwt_denylists'
  
  include Devise::JWT::RevocationStrategies::Denylist
  
end
