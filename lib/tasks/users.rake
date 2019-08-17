namespace :users do
  desc 'update users'
    
  namespace :update do
    
    desc 'update password'
    task device_count: :environment do
      uds = User.joins(:user_devices).group(:user_id)
                .having("device_count!=count(*)")
                .select("users.id, device_count, count(*) as new_count")
      uds.each do |user|
      	User.where(id: user.id).update_all(device_count: user.new_count.to_i)
      end
    end

    desc 'todo'
  end

end