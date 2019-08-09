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
  TYPES = { cycle: 1, duration: 2, forever: 3 }

  serialize :cycle, Array

  belongs_to :user
  belongs_to :device

  validates :user_id, :uniqueness => { :scope => :device_id }
  validates :ble_type, inclusion: {in: [TYPES[:cycle], TYPES[:duration], TYPES[:forever]]}

  before_create :enable_user_ble_setting
  before_destroy :disable_user_ble_setting

  def enable_user_ble_setting
    UserDevice.where(:devic_id => self.device_id, :user_id => self.user_id, :visible => true).update_all(has_ble_setting: true)
  end

  def enable_user_ble_setting
    UserDevice.where(:devic_id => self.device_id, :user_id => self.user_id, :visible => true).update_all(has_ble_setting: false)
  end
end