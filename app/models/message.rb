# == Schema Information
#
# Table name: messages
#
#  id                :bigint           not null, primary key
#  user_id           :integer          not null
#  device_id         :integer          not null
#  oper_cmd          :string(20)       not null
#  oper_username     :string(20)
#  device_type       :string(255)      default("lock"), not null
#  content           :string(60)       default("")
#  avatar_path       :string(255)
#  gif_path          :string(255)
#  ori_picture_paths :text(65535)
#  lock_num          :integer
#  lock_type         :integer
#  is_deleted        :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#

class Message < ApplicationRecord
  LOCKTYPES = { finger: 1, password: 2, card: 3, temp_password: 4, ble: 5 }
  
  TYPENAMES = { "1" => "指纹", "2" => "密码", "3" => "门卡", "4" => "临时密码", "5" => "蓝牙" }
  CMD_NAMES = { "reg_finger" => "录入指纹", "reg_password" => "录入密码", "reg_card" => "录入门卡",
  	            "remove_finger" => "删除指纹", "remove_password" => "删除密码", "remove_card" => "删除门卡",
                "check_time" => "同步时间", "finger_open_door" => "指纹开门", "app_open_door" => "APP开门",
                "update_password" => "修改密码", "update_temp_password" => "修改临时密码", "init" => "重置设备",
                "password_open_door" => "密码开门", "card_open_door" => "门卡开门", "reg_temp_password" => "录入临时密码",
  	            "get_open_num" => "获取开门次数", "get_qoe" => "获取电量", "ble_open_door" => "蓝牙开门" }

  belongs_to :user
  belongs_to :device

  validates :content, length: { allow_blank: true, maximum: 50 }

  scope :visible, -> { where(is_deleted: false).order("messages.id desc") }
  scope :invisible, -> { where(is_deleted: true) }
  scope :smart_lock, -> { where(device_type: "lock") }
  
  scope :today, -> { where("DATE(created_at)=?", Date.today) }
  scope :yesterday, -> { where("DATE(created_at)=?", Date.today-1) }
  scope :last_week, -> { where("DATE(created_at)>?", Date.today-7) }

  def lock_number
  	(self.lock_num.blank? || self.oper_cmd=="get_qoe") ? "" : self.lock_num
  end
end
