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

module Dns
  module CatalogZone
    class Daemon
      class Data
        def initialize(setting)
          @mutex    = Mutex.new
          @setting  = setting
          @source   = Dns::CatalogZone::Source.create(setting)
          @output   = Dns::CatalogZone::Output.create(setting)
          @provider = Dns::CatalogZone::Provider.create(setting)
          @soa      = nil
          @serial   = 0
          @refresh_time = 0
          @retry = 60
          @retry_num = 0
        end
        def set_refresh
          @mutex.synchronize do
            @refresh_time = Time.now.to_i
          end
        end
        def refresh(update = false)
          return if @refresh_time > Time.now.to_i
          @mutex.synchronize do
            Thread.new do
              begin
                @zone_data = @source.get
                @zone_data.each do |rr|
                  next unless rr.type == Dnsruby::Types::SOA
                  @soa = Dnsruby::RR.create(rr.to_s)
                  @refresh_time = Time.now.to_i + rr.refresh
                  next unless @serial > rr.serial
                  update = true
                  @serial = rr.serial
                  @retry  = rr.retry
                  @retry_num = 0
                  break
                end
              rescue
                @refresh_time = Time.now.to_i + @retry * @retry_num
                Daemon.log_error("[#{@setting.zonename}] AXFR ERROR")
              end
              if update
                catalog_zone = Dns::CatalogZone::CatalogZone.new(@setting.zonename, @zone_data)
                provider = Dns::CatalogZone::Provider.create(@setting)
                provider.make(catalog_zone)
                @output.output(provider.write)
                provider.reconfig
              end
            end
          end
        end
      end
    end
  end
end
