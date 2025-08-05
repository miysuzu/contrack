require 'base64'
require 'json'
require 'net/https'
require 'uri'

module Vision
  class << self
    def get_text_from_image(image_file)
      api_key = ENV['GOOGLE_API_KEY']
      api_url = "https://vision.googleapis.com/v1/images:annotate?key=#{api_key}"

      base64_image = Base64.strict_encode64(image_file.tempfile.read)

      params = {
        requests: [
          {
            image: {
              content: base64_image
            },
            features: [
              {
                type: 'DOCUMENT_TEXT_DETECTION'
              }
            ]
          }
        ]
      }.to_json

      uri = URI.parse(api_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request.body = params

      response = https.request(request)
      body = JSON.parse(response.body)

      if body['responses'].nil? || body['responses'].first['error'].present?
        raise "Vision API Error: #{body['responses'].first['error']}"
      end

      body['responses'].first['fullTextAnnotation']['text']
    end
  end
end
