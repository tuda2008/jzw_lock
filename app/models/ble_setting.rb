# == Schema Information
#
# Table name: ble_settings
#
#  id         :bigint           not null, primary key
#  user_id    :integer          not null
#  device_id  :integer          not null
#  cycle      :string(255)
#  start_at   :datetime         not null
#  end_at     :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BleSetting < ApplicationRecord
end
