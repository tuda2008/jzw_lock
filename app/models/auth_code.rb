# == Schema Information
#
# Table name: auth_codes
#
#  id         :bigint           not null, primary key
#  code       :string(255)
#  mobile     :string(255)
#  auth_type  :integer
#  verified   :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AuthCode < ApplicationRecord
end
