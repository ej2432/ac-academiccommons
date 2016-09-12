require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.

# old
#Bundler.require(:default, Rails.env) if defined?(Bundler)

# =============== new start =================== #

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

# =============== new end ==================== #

module AcademicCommons
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Loading configuration files for Solr, Fedora, Indexing, emails
    # TODO: This can be removed in Rails 4. Rails 4 automates this process.
    [:solr, :fedora, :indexing, :emails, :google_analytics].each do |i|
      config_file = File.expand_path("../#{i}.yml", __FILE__) ## Do this better.
      if File.exists? config_file
        settings = ERB.new(IO.read(config_file)).result
        config.send("#{i}=", YAML::load(settings)[Rails.env.to_s])
      end
    end

    config.logger = Logger.new("#{Rails.root}/log/#{Rails.env}.log", 50, 2048000)
    #config.logger = Logger.new("#{Rails.root}/log/#{Rails.env}.log", 'daily')

    # Analytics disabled by default. Google analytics should be enabled in a
    # per-environment basis.
    config.analytics_enabled = false

    config.related_content_solr_url = "http://***REMOVED***:8080/solr-1.5/ac_plus"
    config.related_content_show_size = "3"

    config.prod_environment = false

    # Always throw errors if there is a problem sending an email.
    config.action_mailer.raise_delivery_errors = true

    # Enable the asset pipeline.
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
