module Scalr
  class Ssher
    attr_reader :exit_status, :farm_id, :key_path, :params, :server

    def initialize(params)
      @params  = params
      @exit_status = 0
    end

    def execute(remote_command = '')
      return unless identify_server
      return unless check_key_path

      cmd = params.has_key?('cmd') ? params['cmd'].value : 'ssh'
      command = "#{cmd} -i #{key_path} root@#{server.external_ip} #{remote_command}"
      puts "Executing `#{command}`"
      exec command
    end

    def execute_scp_in(download_path, local_path)
      unless download_path && local_path
        $stderr.puts("Cannot SCP: both download path (#{download_path}) and local path (#{local_path}) must be defined.")
        @exit_status = 1
        return
      end

      return unless identify_server
      return unless check_key_path

      command = "scp -i #{key_path} root@#{server.external_ip}:#{download_path} #{local_path}"
      puts "Executing `#{command}`"
      exec command
    end

    def execute_scp_out(local_path, download_path)
      unless download_path && local_path
        $stderr.puts("Cannot SCP: both download path (#{download_path}) and local path (#{local_path}) must be defined.")
        @exit_status = 1
        return
      end

      return unless identify_server
      return unless check_key_path

      command = "scp -i #{key_path} #{local_path} root@#{server.external_ip}:#{download_path}"
      puts "Executing `#{command}`"
      exec command
    end

  private
    def check_key_path
      return @key_path if @key_path

      @key_path = File.expand_path("~/.ssh/FARM-#{farm_id}.#{server.platform_properties.availability_zone_brief}.private.pem")
      unless File.exists?(key_path)
        $stderr.puts(<<-KEYFILE.gsub(/^ {10}/, ''))

          Expected key file (#{key_path}) does not exist.
          Here's how to fix it:
            - go to https://my.scalr.com/#/sshkeys/view
            - find the row with the 'Farm ID' column as #{farm_id}
            - click the 'Actions' dropdown in its far right column
            - choose 'Download private key'
            - store it to #{key_path}
            - execute: 'chmod 400 #{key_path}'
              (so ssh won't complain about permissive permissions)
        KEYFILE
        @exit_status = 1
      end
      @key_path
    end

    def dispatch(action_name, params)
      Scalr::Caller.new(action_name).dispatch(params)
    end

    def identify_server
      return @server if @server

      response = dispatch(:farm_get_details, params)
      return if generic_error(response)

      @server = Scalr::ResponseObject::FarmRole.
                  single_server(response.content, params['server'].value)
      if @server
        @farm_id = response.request_inputs['FarmID']
      else
        $stderr.puts("Failed to identify server with: #{params['server'].value}")
        @exit_status = 1
      end
      @server
    end
  end
end
