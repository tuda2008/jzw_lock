# == Schema Information
#
# Table name: faqs
#
#  id         :bigint           not null, primary key
#  title      :string(255)      not null
#  content    :text(65535)
#  images     :string(255)
#  visible    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Faq < ApplicationRecord
  mount_uploaders :images, PhotoUploader
  serialize :images, Array

  validates :title, presence: true, uniqueness: { case_sensitive: false }, length: { in: 8..120 }
  validates :content, length: { allow_blank: true, maximum: 3000 }

  scope :visible, -> { where(visible: true) }
  scope :invisible, -> { where(visible: false) }
end
