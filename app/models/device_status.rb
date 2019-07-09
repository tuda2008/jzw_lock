# == Schema Information
#
# Table name: device_statuses
#
#  id          :bigint           not null, primary key
#  name        :string(50)       default("未绑定"), not null
#  category_id :integer          not null
#  enable      :boolean          default(TRUE)
#

class DeviceStatus < ApplicationRecord
	BINDED = 2
	UNBIND = 1
  belongs_to :category

  has_many :devices, foreign_key: :status_id

  validates :name, :category_id, :enable, presence: true
  validates :name, uniqueness: { :scope => :category_id, case_sensitive: false }, length: { in: 2..10 }

  scope :enable, -> { where(enable: true) }
  scope :disable, -> { where(enable: false) }
end
