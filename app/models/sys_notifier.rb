# == Schema Information
#
# Table name: sys_notifiers
#
#  id            :bigint           not null, primary key
#  device_id     :integer          not null
#  author_id     :integer          not null
#  notifier_type :integer          default(1), not null
#  disabled      :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class SysNotifier < ApplicationRecord
	TYPE_OPEN_WARN = 1   #挟持
	TYPE_TRY_ERROR = 2   #设防
	TYPE_INIT_INFO = 3   #解绑

  has_one :notifier_detail

  belongs_to :device
  belongs_to :user, foreign_key: :author_id

  validates :device_id, :uniqueness => { :scope => [:author_id, :notifier_type] }
  validates :notifier_type, inclusion: { in: [TYPE_OPEN_WARN, TYPE_TRY_ERROR, TYPE_INIT_INFO] } 

  scope :disable, -> { where(disable: true) }
  scope :enable, -> { where(disable: false) }
end