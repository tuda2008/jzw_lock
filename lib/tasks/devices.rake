namespace :devices do
  desc 'update devices'
    
  namespace :update do
    
    desc 'reset devices'
    task reset: :environment do
      mac = ""
      p "start reset..."
      @device = Device.where(mac: mac).first
      @device.remove_relevant_collections
      p "end reset."
    end

    desc 'todo'
  end

end