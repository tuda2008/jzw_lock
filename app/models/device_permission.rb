# == Schema Information
#
# Table name: device_permissions
#
#  id            :bigint           not null, primary key
#  device_id     :integer          not null
#  ownership     :integer          not null
#  permission_id :integer          not null
#

class DevicePermission < ApplicationRecord
end
