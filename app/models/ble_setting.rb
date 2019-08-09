# == Schema Information
#
# Table name: ble_settings
#
#  id             :bigint           not null, primary key
#  user_id        :integer          not null
#  device_id      :integer          not null
#  ble_type       :integer          not null
#  cycle          :string(255)
#  cycle_start_at :string(255)
#  cycle_end_at   :string(255)
#  start_at       :datetime
#  end_at         :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BleSetting < ApplicationRecord
end
