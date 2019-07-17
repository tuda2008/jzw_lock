# == Schema Information
#
# Table name: invitations
#
#  id                     :bigint           not null, primary key
#  user_id                :integer          not null
#  inviter_id             :integer          not null
#  device_id              :integer          not null
#  invitation_token       :string(255)      not null
#  invitation_expired_at  :datetime
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#

class Invitation < ApplicationRecord
  MAX_LIMIT = 5
  MAX_DAYS_EXPIRED = 3

  belongs_to :device
  belongs_to :user

  has_many :user_invitors, :dependent => :destroy

  validates :invitation_token, uniqueness: { case_sensitive: false }
end
