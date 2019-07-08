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
end
