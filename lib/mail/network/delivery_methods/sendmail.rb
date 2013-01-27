require 'mail/check_delivery_params'

module Mail
  # A delivery method implementation which sends via sendmail.
  #
  # To use this, first find out where the sendmail binary is on your computer,
  # if you are on a mac or unix box, it is usually in /usr/sbin/sendmail, this will
  # be your sendmail location.
  #
  #   Mail.defaults do
  #     delivery_method :sendmail
  #   end
  #
  # Or if your sendmail binary is not at '/usr/sbin/sendmail'
  #
  #   Mail.defaults do
  #     delivery_method :sendmail, :location => '/absolute/path/to/your/sendmail'
  #   end
  #
  # Then just deliver the email as normal:
  #
  #   Mail.deliver do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  # Or by calling deliver on a Mail message
  #
  #   mail = Mail.new do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  #   mail.deliver!
  class Sendmail
    include Mail::CheckDeliveryParams

    def initialize(values)
      self.settings = { :location       => '/usr/sbin/sendmail',
                        :arguments      => '-i -t' }.merge(values)
    end

    attr_accessor :settings

    def deliver!(mail)
      check_params(mail)

      envelope_from = mail.return_path || mail.sender || mail.from_addrs.first
      return_path = "-f " + '"' + envelope_from.escape_for_shell + '"' if envelope_from

      arguments = [settings[:arguments], return_path].compact.join(" ")

      self.class.call(settings[:location], arguments, mail.destinations.collect(&:escape_for_shell).join(" "), mail)
    end

    def self.call(path, arguments, destinations, mail)
      popen "#{path} #{arguments} #{destinations}" do |io|
        io.puts mail.encoded.to_lf
        io.flush
      end
    end

    if RUBY_VERSION < '1.9.0'
      def self.popen(command, &block)
        IO.popen "#{command} 2>&1", 'w+', &block
      end
    else
      def self.popen(command, &block)
        IO.popen command, 'w+', :err => :out, &block
      end
    end
  end
end
