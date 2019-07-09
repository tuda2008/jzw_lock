# == Schema Information
#
# Table name: notifier_details
#
#  id              :bigint           not null, primary key
#  sys_notifier_id :integer          not null
#  mobile          :string(255)      default("")
#  content         :string(255)      default("")
#  created_at      :datetime         not null
#

class NotifierDetail < ApplicationRecord
	belongs_to :sys_notifier

	validates :mobile, length: { in: 11..12 }
	validates :content, length: { in: 2..60 }
end