fetch(:default_env).merge!(rails_env: :production)

set :stage, :production
set :user, 'ubuntu'
set :ssh_options, {
          forward_agent: true
        }

production_servers = %w(
  LR-Pres-1
  LR-Pres-2
)

role :web, production_servers
role :app, production_servers
