require 'httpi'
require 'json'

HTTPI.log = false

module AfterShip
  module V3
    class Base

      def self.call(http_verb_method, end_point, params = {}, body = {})
        url = "#{AfterShip::URL}/v3/#{end_point.to_s}"
        unless params.empty?
          url += '?' + Rack::Utils.build_query(params)
        end

        unless body.empty?
          body.each do |k, v|
            HTTPI.logger.warn("the #{k} field  should be an array") if %w(emails smses).include?(k.to_s) && !v.is_a?(Array)
          end
        end

        uri = URI.parse(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req_klass_name = 'Net::HTTP::' + http_verb_method.capitalize
        req_klass = eval(req_klass_name)
        req = req_klass.new(uri.request_uri)
        req.add_field('aftership-api-key', AfterShip.api_key)
        req.add_field('Content-Type', 'application/json')
        req.body = body.to_json

        response = https.start { |handler| handler.request(req) }

        # different
        if response.nil?
          raise(AfterShipError.new("response is nil"))
        else
          return JSON.parse(response.raw_body)
        end
      end

      class AfterShipError < StandardError;

      end
    end
  end
end
