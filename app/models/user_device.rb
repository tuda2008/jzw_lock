# == Schema Information
#
# Table name: user_devices
#
#  id        :bigint           not null, primary key
#  author_id :integer          not null
#  user_id   :integer          not null
#  device_id :integer
#  ownership :integer          default(1), not null
#  visible   :boolean          default(TRUE)
#

class UserDevice < ApplicationRecord
  OWNERSHIP = { user: 1, admin: 2, super_admin: 3 }
  MAX_ADMIN_LIMIT = 3

  belongs_to :user
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

  before_destroy :soft_remove_messages

  def soft_remove_messages
    if self.ownership == OWNERSHIP[:user]
      Message.where(user_id: self.user_id, device_id: self.device_id).update_all(is_deleted: true)
    end
  end

  def is_super_admin?
  	self.ownership == OWNERSHIP[:super_admin]
  end

  def is_admin?
  	self.ownership == OWNERSHIP[:super_admin] || self.ownership == OWNERSHIP[:admin]
  end
end
