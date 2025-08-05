class ApplicationMailer < ActionMailer::Base
  default from: ENV['MAIL_FROM'] || 'noreply@contrack.com'
  layout 'mailer'
end
