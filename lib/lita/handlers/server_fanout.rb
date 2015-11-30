module Lita
  module Handlers
  	require 'net/ssh'
    class ServerFanout < Handler
    	config :ssh_key
    	config :server_groups
    	config :server_commands

#“smart quotes”
			route(/^fanout ["|“]([^"“”].+)["|”] (.*)/, :fanout,
				command: true,
				help: {
			  	"fanout" => "run a command on a bunch of servers"
				})

			route(/^fanout list groups/, :list_groups,
				command: true,
				help: {
			  	"fanout list groups" => "list stored server groups"
				})

			route(/^fanout list commands/, :list_commands,
				command: true,
				help: {
			  	"fanout list commands" => "list stored server commands"
				})


			def list_groups(response)
				server_groups = Lita.config.handlers.server_fanout.server_groups
				if server_groups
					server_groups.each { |k, v|
						response.reply "#{k.to_s}: #{v}"
					}
				else
					response.reply "Sorry, no groups defined"
				end
			end

			def list_commands(response)
				server_commands = Lita.config.handlers.server_fanout.server_commands
				if server_commands
					server_commands.each { |k, v|
						response.reply "#{k.to_s}: #{v}"
					}
				else
					response.reply "Sorry, no commands defined"
				end
			end


			def fanout(response)
				servers = response.matches[0][0].strip
				command = response.matches[0][1].strip

				if servers == "" || command == ""
					response.reply "Sorry, I'm having trouble understanding you :("
				end

				key = Lita.config.handlers.server_fanout.ssh_key

				# response.reply "looking up #{servers} / #{command}"

				server_groups = Lita.config.handlers.server_fanout.server_groups
				if server_groups && server_groups[servers.to_sym]
					servers = server_groups[servers.to_sym]
				end

				server_commands = Lita.config.handlers.server_fanout.server_commands
				if server_commands && server_commands[command.to_sym]
					command = server_commands[command.to_sym]
				end

				servers.split(/ +/).each { |s|
					user, host = s.split(/@/)
					Net::SSH.start( host, user, key_data:key, keys_only:true ) do |ssh|
						result = ssh.exec!(command)
						response.reply "#{host}: #{result}"
					end 
				}
			end

      Lita.register_handler(self)
    end
  end
end
