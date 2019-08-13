# == Schema Information
#
# Table name: devices
#
#  id         :bigint           not null, primary key
#  uuid       :string(10)
#  mac        :string(40)
#  token      :string(40)       not null
#  product_id :integer
#  status_id  :integer          default(2), not null
#  alias      :string(50)       default("门锁"), not null
#  address    :string(120)      default("")
#  imei       :string(60)       default("")
#  open_num   :integer          default(0)
#  low_qoe    :boolean          default(FALSE)
#  wifi_mac   :string(30)
#  port       :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Device < ApplicationRecord
  SALT = ""
  has_many :user_devices, :dependent => :destroy
  has_many :users, :through => :user_devices, source: :user

  has_one :super_user_device, -> {where :user_devices => {ownership: UserDevice::OWNERSHIP[:super_admin]}}, class_name: :UserDevice
  has_one :super_admin, through: :super_user_device, class_name: :User

  has_many :admin_user_devices, -> {where :user_devices => {ownership: UserDevice::OWNERSHIP[:admin]}}, class_name: :UserDevice
  has_many :admin_users, through: :admin_user_devices, class_name: :User

  has_many :all_admin_user_devices, -> {where "user_devices.ownership=#{UserDevice::OWNERSHIP[:super_admin]} or user_devices.ownership=#{UserDevice::OWNERSHIP[:admin]}"}, class_name: :UserDevice
  has_many :all_admin_users, through: :all_admin_user_devices, class_name: :User

  has_many :messages, :dependent => :destroy

  belongs_to :device_status, foreign_key: :status_id

  has_many :invitations, :dependent => :destroy
  has_many :user_invitors, :through => :invitations

  has_many :sys_notifiers

  validates :alias, length: { in: 1..10 }
  validates :mac, length: { in: 12..40 }

  def name
    self.alias
  end

  def is_admin?(user_id)
    ud = self.user_devices.visible.where(user_id: user_id).first
    !ud.nil? && ud.is_admin?
  end

  def ownership?(user_id)
    ud = self.user_devices.visible.where(user_id: user_id).first
    ud.ownership if ud
  end

  def invitations_by_user(user_id)
    self.invitations.where(:invitations => { user_id: user_id })
  end

  def user_invitors_by_user(user_id)
    self.user_invitors.where(:invitations => { user_id: user_id })
  end

  def invitors
    User.joins("inner join user_invitors ui on users.id=ui.user_id 
                inner join invitations it on it.id=ui.invitation_id")
    .select("distinct users.id, users.nickname, users.avatar_url")
    .where("it.device_id=?", self.id)
  end

  def invitors_by_user(user_id)
    User.joins("inner join user_invitors ui on users.id=ui.user_id 
                inner join invitations it on it.id=ui.invitation_id")
    .select("distinct users.id, users.nickname, users.avatar_url")
    .where("it.device_id=? and it.user_id=?", self.id, user_id)
  end

  def self.devices_by_user(user, page, per_page)
    Device.joins(:user_devices).joins("inner join users on users.id=user_devices.author_id")
    .select("devices.*, users.nickname, user_devices.ownership")
    .where(:status_id => DeviceStatus::BINDED).where("user_id=? and visible=true", user.id)
    .order("user_devices.ownership").page(page).per(per_page)
  end

  def remove_relevant_collections
    self.update_attribute(:status_id, DeviceStatus::UNBIND)
    UserDevice.where(:device => self).each do |ud|
      ud.destroy
    end
    Message.where(:device_id => self.id).update_all(is_deleted: true)
    DeviceUser.where(:device_id => self.id).each do |du|
      du.destroy
    end
    BleSetting.where(:device_id => self.id).each do |bs|
      bs.destroy
    end
  end
end