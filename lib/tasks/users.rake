namespace :users do
  desc 'update users'
    
  namespace :update do
    
    desc 'update password'
    task device_count: :environment do
      User.joins("left join user_devices on user_devices.user_id=users.id")
          .where("user_devices.user_id is null and users.device_count>0")
          .update_all(device_count: 0)

      uds = User.joins(:user_devices).group(:user_id)
                .having("device_count!=count(*)")
                .select("users.id, device_count, count(*) as new_count")
      uds.each do |user|
        user.update_attribute(:device_count, user.new_count.to_i)
        #User.where(id: user.id).update_all(device_count: user.new_count.to_i)
      end
    end
    
    desc 'todo'
  end

end