CarrierWave.configure do |config|
  if Rails.env.production?
  	config.asset_host = 'https://api.jinzhiwen.com'
  else
  	config.asset_host = ''
  end
  config.permissions = 0666
  config.directory_permissions = 0777
  config.storage = :file
end