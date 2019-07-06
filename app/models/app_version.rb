# == Schema Information
#
# Table name: app_versions
#
#  id            :bigint           not null, primary key
#  code          :integer          default(1), not null
#  name          :string(255)      not null
#  mobile_system :integer          default(3), not null
#  content       :text(65535)      not null
#  created_at    :datetime
#

class AppVersion < ApplicationRecord
  MOBILESYSTEMS = { ios: 1, android: 2, wechat_mini: 3, alipay_mini: 4 }
  MOBILESYSTEM_COLLECTION = [["IOS", 1], ["Android", 2], ["微信小程序", 3], ["支付宝小程序", 4]]
  MOBILESYSTEM_HASH = { 1 => "IOS", 2 => "Android", 3 => "微信小程序", 4 => "支付宝小程序" }

  validates :code, :name, :mobile_system, :content, presence: true
  validates :code, :uniqueness => { :scope => :mobile_system }
  validates :name, :uniqueness => { :scope => :mobile_system }


  scope :ios, -> { where(mobile_system: MOBILESYSTEMS[:ios]) }
  scope :android, -> { where(mobile_system: MOBILESYSTEMS[:android]) }
  scope :wechat, -> { where(mobile_system: MOBILESYSTEMS[:wechat_mini]) }
  scope :alipay, -> { where(mobile_system: MOBILESYSTEMS[:alipay_mini]) }
end
