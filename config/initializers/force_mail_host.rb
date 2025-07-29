if Rails.env.production?
  Rails.application.config.action_mailer.default_url_options = { host: '57.181.155.52' }
end
