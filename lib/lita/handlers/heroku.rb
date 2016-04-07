require "json"
require "open3"
module Lita
  module Handlers
    class Heroku < Handler
      config :oauth_token, required: true
      config :app_prefix
      config :bitly_access_token

      route(/^hk\s+([^ ]+)\s+(.+)/, :heroku_cmd, command: true, help: {
        "hk [app name] [command]" => "example: 'lita hk production ps'",
        "hk [app name] deploy" => "example: 'lita hk production deploy'"
      })

      def heroku_cmd(response)
        environment = response.matches[0][0]
        command = response.matches[0][1]
        if command.start_with? "deploy"
          heroku_deploy response
        else
          stream_command response, "#{heroku_bin} #{command} -a #{config.app_prefix}#{environment}"
        end
      end

      def heroku_bin
        @heroku_bin ||= if `type heroku 2>&1 | grep -v "not found"`.empty?
          if `ls /usr/local/heroku/bin/heroku 2> /dev/null`.empty?
            raise "Couldn't find heroku binary; please install the Heroku Toolbelt"
          else
            "/usr/local/heroku/bin/heroku"
          end
        else
          "heroku"
        end
      end

      def heroku_deploy(response)
        bearer = config.oauth_token
        app_name, command, branch = response.matches[0].join(" ").split
        app_name = "#{config.app_prefix}#{app_name}" unless app_name.start_with? config.app_prefix
        branch ||= "master"

        apps = JSON.parse `curl -s "https://api.heroku.com/apps" -H "Authorization: Bearer #{bearer}" -H 'Accept: application/vnd.heroku+json; version=3'`
        app = apps.select{|app| app["name"] == app_name }.first
        app_id = app["id"]

        build_response = `curl -s "https://kolkrabbi.herokuapp.com/apps/#{app_id}/github/push" -H "Authorization: Bearer #{bearer}" -d '{"branch":"#{branch}"}'`
        build_response = JSON.parse build_response

        $stdout.puts build_response

        if build_response.key?("build") && build_response["build"]["status"] == "pending"
          response_text = "Deploying #{branch} to #{app_name}. "
          if config.bitly_access_token
            bitly_response = JSON.parse `curl -sGX GET --data-urlencode "longUrl=#{build_response["build"]["output_stream_url"]}" "https://api-ssl.bitly.com/v3/shorten?access_token=#{config.bitly_access_token}"`
            response_text += "Build output at: #{bitly_response['data']['url']}."
          end
          response.reply response_text
        else
          response.reply("Deploy could not be started. Response: #{build_response}")
        end
      end

      def api(bearer, uri, data=nil)
        cmd  = %Q{curl -s "https://kolkrabbi.herokuapp.com#{uri}" -H "Authorization: Bearer #{bearer}" -H 'range: name ..; order=asc, max=1000'}
        cmd += %Q{-d '#{data}'} if data
        JSON.parse `#{cmd}`
      end

      private

      def stream_command response, command
        channel = response.message.source.room

        Open3.popen2e(command) do |stdin, stdout_and_stderr, thread|
          response.reply "```\nStarting `#{command.gsub "\n", '\\n'}`:\n```"
          timestamp, text = get_last_message channel

          last_update = Time.now.to_i - 2
          text_response = String.new

          while line = stdout_and_stderr.gets
            text.gsub!("```", "")
            text += line
            text_response = "```#{text}```"
            if Time.now.to_i - last_update > 2
              last_update = Time.now.to_i
              update_response channel, timestamp, text_response
            end
          end
          update_response channel, timestamp, text_response
        end
      end

      def update_response channel, timestamp, text
        robot.chat_service.api.send(
          :call_api, "chat.update", { channel: channel, ts: timestamp, as_user: true, text: text }
        )
      end

      def get_last_message channel
        channel_type = channel[0] == "D" ? 'im' : 'channels'
        msg = robot.chat_service.api.send(
          :call_api, "#{channel_type}.history", { channel: channel, count: 1 } # Probably need to filter
        )
        [msg["messages"][0]["ts"], msg["messages"][0]["text"]]
      end

      Lita.register_handler(self)
    end
  end
end
