# == Schema Information
#
# Table name: user_invitors
#
#  id            :bigint           not null, primary key
#  invitation_id :integer          not null
#  user_id       :integer          not null
#  created_at    :datetime
#

class UserInvitor < ApplicationRecord
  belongs_to :user
  belongs_to :invitation

  belongs_to :invitors, foreign_key: :user_id, class_name: :User

  validates :user_id, :invitation_id, presence: true
  validates :user_id, :uniqueness => { :scope => :invitation_id }
end
