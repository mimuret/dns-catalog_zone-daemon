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
require 'eventmachine'
require 'pp'
module Dns
  module CatalogZone
    class Daemon
      class Refresher
        attr_accessor :data
        attr_accessor :interval
        def self.run(data)
          refresher = Refresher.new(1, data)
          refresher
        end
        def initialize(interval, data)
          @interval = interval
          @data = data
          @cancelled = false
          @work = method(:fire)
          schedule
        end
        def cancel
          @cancelled = true
        end
        def schedule
          EventMachine::add_timer @interval, @work
        end
        def fire
          unless @cancelled
            refresh
            schedule
          end
        end
        def refresh
          Daemon.log_debug 'start refresh'
          @data.keys.each do |zonename|
            @data[zonename].refresh
          end
          Daemon.log_debug 'end refresh'
        end
        def reload(data)
          @data = data
        end
      end
    end
  end
end
