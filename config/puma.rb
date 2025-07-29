# Puma configuration

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"
environment ENV.fetch("RAILS_ENV") { "production" }

# UNIXソケットでバインド
bind "unix://#{Rails.root.to_s}/tmp/sockets/puma.sock"

# 本番環境の設定
if Rails.env.production?
  pidfile "#{Rails.root.to_s}/tmp/pids/puma.pid"
  state_path "#{Rails.root.to_s}/tmp/pids/puma.state"
  stdout_redirect "#{Rails.root.to_s}/log/puma.stdout.log", "#{Rails.root.to_s}/log/puma.stderr.log", true
  daemonize true
end

# 再起動対応
plugin :tmp_restart
