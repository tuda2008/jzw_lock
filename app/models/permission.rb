# == Schema Information
#
# Table name: permissions
#
#  id         :bigint           not null, primary key
#  product_id :integer          not null
#  permission :string(255)      not null
#  visible    :boolean          default(TRUE)
#

class Permission < ApplicationRecord
end
