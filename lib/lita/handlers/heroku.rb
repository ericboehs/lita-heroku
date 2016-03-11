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
          stdout, stderr, status = Open3.capture3 "#{heroku_bin} #{command} -a #{config.app_prefix}#{environment}"
          response_text = "```\n"
          response_text += stdout
          response_text += stderr
          response_text += "Exited with status #{status.exitstatus}" unless status.exitstatus.zero?
          response_text += "```"
          response.reply response_text
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

      Lita.register_handler(self)
    end
  end
end
