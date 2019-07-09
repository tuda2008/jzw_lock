# == Schema Information
#
# Table name: wechat_form_ids
#
#  id       :bigint           not null, primary key
#  user_id  :integer          not null
#  form_ids :text(65535)
#

class WechatFormId < ApplicationRecord
	serialize :form_ids, Array

	belongs_to :user
end
