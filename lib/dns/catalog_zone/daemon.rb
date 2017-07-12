# The MIT License (MIT)
#
# Copyright (c) 2017 Manabu Sonoda
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'dns/catalog_zone'
require 'dns/catalog_zone/daemon/data'
require 'dns/catalog_zone/daemon/receiver'
require 'dns/catalog_zone/daemon/refresher'
require 'dns/catalog_zone/daemon/version'

require 'optparse'
require 'syslog/logger'
require 'eventmachine'

module Dns
  module CatalogZone
    class Daemon
      class << self
        def logger
          @@logger ||= Syslog::Logger.new('catzd')
        end
        def log_error(message)
          STDERR.puts message
          logger.error(message)
        end
        def log_fatal(message)
          STDERR.puts message
          logger.fatal(message)
        end
        def log_debug(message)
          puts message
          logger.debug(message)
        end
        def log(message)
          puts message
          logger.info(message)
        end
        def start
          config = { 'config' => 'CatalogZone',
                     'pidfile' => '/var/run/catz.pid',
                     'port' => 5300,
                     'listen' => '127.0.0.1'
          }
          opts = OptionParser.new
          opts.on('-c','--config CONFIG') {|s| config['config'] = s }
          opts.on('-i','--pidfile PIDFILE') {|s| config['pidfile'] = s }
          opts.on('-p','--port PORT') {|p| config['port'] = p.to_i }
          opts.on('-l','--listen IP') {|s| config['listen'] = s }
          opts.parse!(ARGV)
          begin
            daemon = Dns::CatalogZone::Daemon.new(config)
            daemon.run
          rescue Dns::CatalogZone::ConfigNotFound
            Daemon.log_error("config file not found")
          ensure
            daemon.stop if daemon
          end
        end
      end
      def initialize(config)
        @config = config
        @catalog_zones = Hash.new
        if File.exist?(@config['pidfile'])
          pid = File.read(@config['pidfile']).chomp!.to_i
          if process_alive(pid)
            puts "already running daemon pid #{pid}"
            exit 0
          end
        end
        begin
          File.open(@config['pidfile'], 'w') do |pidfile|
            pidfile.puts($PROCESS_ID)
          end
        rescue
          Daemon.log_error "[ERROR] pidfile #{@config['pidfile']} is not writable"
          exit 1
        end
      end
      def process_alive(pid)
        Process.getpgid(pid)
        return true
      rescue
        return false
      end
      def run
        zone_init
        EM.run do
          @refresher = Daemon::Refresher.run(@data)
          @receiver  = Daemon::Receiver.run(@config['listen'], @config['port'], @data)
          Signal.trap('HUP')  { reload }
          Signal.trap('INT')  { EventMachine.stop ; stop}
          Signal.trap('TERM') { EventMachine.stop ; stop}
        end
      end
      def zone_init
        data = {}
        catz_config = loadConfig
        catz_config.settings.each_with_index do |setting,i|
          data[Dnsruby::Name.create(setting.zonename).canonical] = Data.new(setting)
        end
        @data = data
      end


      def stop
        File.unlink(@config['pidfile']) if File.exist?(@config['pidfile'])
      end

      def reload
        zone_init
        @refresher.reload(@data)
        @receiver.reload(@config['listen'], @config['port'], @data)
      end

      def status
      end

      private
      def loadConfig
        catz_config = Dns::CatalogZone::Config.read(@config['config'])
        catz_config.settings.each do |setting|
          raise "[ERROR] setting[#{setting.name}] source type is not axfr." if setting.source != 'axfr'
          setting.validate
        end
        catz_config
      end
    end
  end
end
