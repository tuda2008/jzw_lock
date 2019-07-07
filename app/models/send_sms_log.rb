# == Schema Information
#
# Table name: send_sms_logs
#
#  id                :bigint           not null, primary key
#  mobile            :string(255)
#  send_type         :integer
#  sms_total         :integer          default(0)
#  first_sms_sent_at :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class SendSmsLog < ApplicationRecord
end
