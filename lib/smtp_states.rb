class NotInitializedError < RuntimeError; end

module Messages

  END_LINE = "\r\n"

  def greeting(io)
    send_message io, '220 ruby ESMTP'
  end

  def helo_response(io)
    send_message io, '250 ruby'
  end

  def ok(io)
    send_message io, '250 ok'
  end

  def go_ahead(io)
    send_message io, '354 go ahead'
  end

  def goodbye(io)
    send_message io, '221 ruby goodbye'
  end

  private

  def send_message(io, msg)
    io << msg
    io << END_LINE
  end


end

class InitState

  include Messages

  def serve(io)
    greeting(io)

    :connect
  end

end

class ConnectState

  include Messages

  def serve(io)
    read_client_helo(io)
    helo_response(io)

    :connected
  end

  def read_client_helo(io)
    io.readline
  end

end

class ConnectedState

  include Messages

  def serve(io)
    request = io.readline

    if request.strip.eql? "DATA"
      go_ahead(io)
      :read_mail
    else
      ok(io)
      :connected
    end
  end

end

class ReadMailState
  attr_accessor :protocol
  include Messages

  def initialize(protocol = nil)
    @protocol = protocol
  end

  def serve(io)
    message = read_message(io)
    @protocol.new_message_received(message)
    ok(io)

    :quit
  end

  def read_message(io)
    message = ''

    line = io.readline
    while not_end_of_message(line)
      message << line
      line = io.readline
    end

    message
  end

  def not_end_of_message(line)
    not line.strip.eql?('.')
  end

end

class QuitState

  include Messages

  def serve(io)
    read_quit(io)
    goodbye(io)

    :done
  end

  private

  def read_quit(io)
    io.readline
  end

end
