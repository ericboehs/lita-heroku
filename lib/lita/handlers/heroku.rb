require "json"
module Lita
  module Handlers
    class Heroku < Handler
      config :bearer, required: true
      config :application_id, required: true

      route(/^hk\s+([^ ]+)\s+(.+)/, :heroku_cmd, command: true, help: {
        "heroku deploy [environment]" => "example: 'lita heroku deploy production'"
      })

      def heroku_cmd(response)
        environment = response.matches[0][0]
        command = response.matches[0][1]
        if command == "deploy"
          heroku_deploy response
        else
          response.reply `#{heroku_bin} #{command} -a hats-#{environment}`
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

      route(/^hk deploy\s+(.+)/, :heroku_deploy, command: true, help: {
        "heroku deploy [environment]" => "example: 'lita heroku deploy production'"
      })

      def heroku_deploy(response)
        app_id = config.application_id
        bearer = config.bearer
        branch = "master"

        build_response = `curl -s "https://kolkrabbi.herokuapp.com/apps/#{app_id}/github/push" -H "Authorization: Bearer #{bearer}" -d '{"branch":"#{branch}"}'`
        build_response = JSON.parse build_response

        if build_response.key?("build") && build_response["build"]["status"] == "pending"
          response.reply("Started deploy")
        end
      end

      Lita.register_handler(self)
    end
  end
end
