module Scalr
  class LogSinks
    def initialize(sinks)
      @sinks = sinks
    end

    def <<(id, log)
      sink = sink_by_id(id)
      sink << log if sink
    end

  private

    def sink_by_id(id)
      @sinks.find {|sink| id == sink.id}
    end
  end

  class LogSink
    def initialize(id)
      @id = id
      @logs = []
    end

    def <<(log)
      @logs << log
    end

    def +(logs)
      logs.each {|log| self << log}
    end

    def config_and_launch_script
      scripting_logs.find {|log_item| log_item.script_name == 'TTMAppConfigAndLaunch'}
    end

    def failures
      scripting_logs.find_all {|l| l.failure?}
    end

    def scripting_logs
      logs_by_class(Scalr::ResponseObject::ScriptLogItem)
    end

    def system_logs
      logs_by_class(Scalr::ResponseObject::LogItem)
    end

  private

    def logs_by_class(clazz)
      @logs.find_all {|log| log.instance_of? clazz}
    end
  end

  require 'delegate'

  class ServerFailure < ::SimpleDelegator

    Dir[File.join(File.dirname(__FILE__), 'failure', '*.rb')].each {|file| require file}

    attr_reader :server, :types

    PATTERNS = [
        Scalr::Failure::S3Authentication.new
    ]

    def initialize(server, log_item)
      super(log_item)
      @server = server
      @types = categorize(log_item)
    end

    def categorize(log_item)
      matches = PATTERNS.find_all {|pattern| pattern.matches?(log_item)}
      matches.empty? ? [Scalr::Failure::Generic.new] : matches
    end
  end


end