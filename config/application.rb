require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JzwLock
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.autoload_paths.push(*%W(#{config.root}/lib))
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # 防止大量IP访问
    config.middleware.use Rack::Attack
    
    # 设置缓存配置
    config.cache_store = :redis_store

    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local

    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = "zh-CN"
    
    config.encoding = "utf-8"
  end
end

I18n.config.enforce_available_locales = false
I18n.locale = 'zh-CN'