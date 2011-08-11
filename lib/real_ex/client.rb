module RealEx
  class Client
    class << self

      def timestamp
        Time.now.strftime('%Y%m%d%H%M%S')
      end

      def build_hash(hash_string_items)
        first_hash = Digest::SHA1.hexdigest(hash_string_items.join('.'))
        Digest::SHA1.hexdigest("#{first_hash}.#{RealEx::Config.shared_secret}")
      end

      def build_xml(type, &block)
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!
        xml.request(:type => type, :timestamp => timestamp) { |r| block.call(r) }
        xml.target!
      end

      def call(url,xml)
        uri = URI.parse(url)

        https = (uri.scheme == 'https')
        if [80, 443].include?(uri.port)
          port = https ? 443 : 80
        else
          port = uri.port
        end

        h = Net::HTTP.new(uri.host, port)
        h.use_ssl = https
        response = h.request_post(uri.path, xml)
        result = Nokogiri.XML(response.body)
        result
      end

      def parse(response)
        status = (response/:result).inner_html
        raise RealExError, "#{(response/:message).inner_html} (#{status})" unless status == "00"
      end
    end
  end
end