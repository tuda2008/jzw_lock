# == Schema Information
#
# Table name: device_users
#
#  id             :bigint           not null, primary key
#  device_id      :integer          not null
#  user_id        :integer
#  device_type    :integer          not null
#  device_num     :integer          not null
#  username       :string(40)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  open_need_warn :boolean          default(FALSE)
#

class DeviceUser < ApplicationRecord
  LOCKTYPES = { finger: 1, password: 2, card: 3, temp_password: 4, ble: 5 }
  TYPENAME = { "1" => "指纹", "2" => "密码", "3" => "门卡", "4" => "临时密码", "5" => "蓝牙" }

  belongs_to :user, optional: true
  belongs_to :device

  validates :device_id, :uniqueness => { :scope => [:device_type, :device_num] }
  validates :username, length: { in: 2..20 }
end