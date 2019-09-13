# == Schema Information
#
# Table name: carousels
#
#  id      :bigint           not null, primary key
#  tag     :string(255)      not null
#  url     :string(255)
#  images  :string(255)
#  visible :boolean          default(FALSE)
#

class Carousel < ApplicationRecord
  TAG_HOME = "home"
  TAG_WELCOME = "welcome"
  TAG_COLLECTION = [["首页", "home"]]
  TAG_HASH = { "home" => "首页" }
  mount_uploaders :images, CarouselUploader
  serialize :images, Array

  validates :tag, presence: true
  validates_uniqueness_of :tag
  validates :tag, inclusion: {in: ['home', 'welcome']} 
  validate :images_not_empty
  
  scope :visible, -> { where(visible: true) }
  scope :invisible, -> { where(visible: false) }
  scope :home, -> { where(tag: TAG_HOME) }
  scope :welcome, -> { where(tag: TAG_WELCOME) }

  # images不能为空检查
  def images_not_empty
    if images.empty?
      errors.add(:base, '展播图片不能为空，至少需要一张图片')
      return false  
    end
  end
end