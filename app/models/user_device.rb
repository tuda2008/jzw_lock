# == Schema Information
#
# Table name: user_devices
#
#  id              :bigint           not null, primary key
#  author_id       :integer          not null
#  user_id         :integer          not null
#  device_id       :integer
#  ownership       :integer          default(1), not null
#  finger_count    :integer          default(0)
#  password_count  :integer          default(0)
#  card_count      :integer          default(0)
#  temp_pwd_count  :integer          default(0)
#  has_ble_setting :boolean          default(FALSE)
#  visible         :boolean          default(TRUE)
#

class UserDevice < ApplicationRecord
  OWNERSHIP = { user: 1, admin: 2, super_admin: 3 }
  MAX_ADMIN_LIMIT = 3

  belongs_to :user, :counter_cache => :device_count
  belongs_to :device
  belongs_to :author, foreign_key: :author_id, class_name: :User
  belongs_to :super_admin, foreign_key: :user_id, class_name: :User
  belongs_to :admin_users, foreign_key: :user_id, class_name: :User
  belongs_to :all_admin_users, foreign_key: :user_id, class_name: :User


  validates :user_id, :device_id, presence: true
  validates :user_id, :uniqueness => { :scope => :device_id }
  #validates :user_id, :uniqueness => { :scope => [:device_id, :ownership] }

  scope :visible, -> { where(visible: true) }
  scope :invisible, -> { where(visible: false) }

  def remove_relevant_collections
    if self.is_admin?
      Message.where(:device_id => self.device_id).update_all(is_deleted: true)
      Device.where(:id => self.device_id).update_all(status_id: DeviceStatus::UNBIND)
      BleSetting.where(:device_id => self.device_id).each do |bs|
        bs.destroy
      end
      DeviceUser.where(:device_id => self.device_id).each do |du|
        du.destroy
      end
      UserDevice.where(:device_id => self.device_id).each do |ud|
        ud.destroy
      end
    end
  end

  def is_super_admin?
  	self.ownership == OWNERSHIP[:super_admin]
  end

  def is_admin?
  	self.ownership == OWNERSHIP[:super_admin] || self.ownership == OWNERSHIP[:admin]
  end

  def self.get_first_device_id_by_user(user_id)
    ud = UserDevice.where(:user_id => user_id, :visible => true).first
    ud.nil? ?  "" : ud.device_id
  end

  def self.get_first_device_id(user_id, device_id)
    ud = UserDevice.where(:user_id => user_id, :device_id => device_id, :visible => true).first
    ud.nil? ?  "" : ud.device_id
  end
end