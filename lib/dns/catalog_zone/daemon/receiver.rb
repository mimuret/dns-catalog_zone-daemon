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
require 'socket'
require 'eventmachine'

module Dns
  module CatalogZone
    class Daemon
      class Receiver
        def self.run(host, port, data)
          reciever = Receiver.new(host, port, data)
          reciever.run
          reciever
        end

        def initialize(host, port, data)
          @data = data
          @port = port
          @host = host
        end

        def reload(data)
          @tcp_server.data = data
          @udp_server.data = data
        end

        def run
          Daemon.log_debug "start tcp server #{@host}:#{@port}"
          @tcp_server = EM.start_server(@host, @port, TcpWorker, @data)
          Daemon.log_debug "start udp server #{@host}:#{@port}"
          @udp_server = EM.open_datagram_socket(@host, @port, UdpWorker, @data)
        end

        class Worker < EventMachine::Connection
          attr_accessor :data
          def initialize(data)
            @data = data
          end

          def receive_dns_message(msg)
            qname = msg.question[0].qname.canonical
            begin
              if msg.header.opcode == Dnsruby::OpCode.Notify
                if @data.key?(qname)
                  msg.header.aa = true
                  msg.header.rcode = Dnsruby::RCode.NOERROR
                  @data.set_refresh
                  Daemon.log_debug("[#{qname}] recieve NOTIFY")
                else
                  Daemon.log_debug("[#{qname}] REFUSED")
                  msg.header.rcode = Dnsruby::RCode.REFUSED
                end
              else
                Daemon.log_debug("[#{qname}] NOTIMP")
                msg.header.rcode = Dnsruby::RCode.NOTIMP
              end
            rescue => e
              Daemon.log_debug(e)
            end
          end
        end
        class UdpWorker < Worker
          def receive_data(data)
            port, ip = Socket.unpack_sockaddr_in(get_peername)
            Thread.new(ip, port, data) do |h, p, d|
              begin
                msg = Dnsruby::Message.decode(d)
                receive_dns_message(msg)
                send_datagram msg.encode, h, p
              end
            end
          end
        end
        class TcpWorker < Worker
          def receive_data(data)
            port, ip = Socket.unpack_sockaddr_in(get_peername)
            Thread.new(ip, port, data) do |_h, _p, d|
              begin
                msg_data = d[2..-1]
                msg = Dnsruby::Message.decode(msg_data)
                receive_dns_message(msg)
                enc = msg.encode
                lenmsg = [enc.length].pack('n')
                send_data lenmsg
                send_data enc
              end
            end
          end
        end
      end
    end
  end
end
