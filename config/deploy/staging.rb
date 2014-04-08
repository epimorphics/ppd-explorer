fetch(:default_env).merge!(rails_env: :production)
set :stage, :production

server 'lr-app-staging',
        roles: %w{web, app},
        user: 'ec2-user',
        ssh_options: {
          forward_agent: true
        }

role :web, %w{lr-app-staging}
