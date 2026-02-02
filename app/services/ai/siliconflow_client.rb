# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Ai
  class SiliconflowClient
    Error = Class.new(StandardError)

    def initialize
      @endpoint = Rails.configuration.x.siliconflow.endpoint.to_s.strip
      @model    = Rails.configuration.x.siliconflow.model.to_s.strip
      @timeout  = Integer(Rails.configuration.x.siliconflow.timeout || 25)
      @api_key  = ENV["SILICONFLOW_API_KEY"].to_s
    end

    # messages: [{role:, content:}, ...]
    def chat(messages, max_tokens: 1024, temperature: 0.2)
      raise Error, "SILICONFLOW_API_KEY missing" if @api_key.empty?
      uri = URI.parse(@endpoint)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise Error, "Invalid endpoint: #{@endpoint.inspect}"
      end

      body = {
        model: @model,
        messages: messages,
        stream: false,
        max_tokens: max_tokens,
        temperature: temperature
      }

      req = Net::HTTP::Post.new(uri)             # 传 URI 本体更安全
      req["Authorization"] = "Bearer #{@api_key}"
      req["Content-Type"]  = "application/json"
      req.body = JSON.generate(body)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = (uri.scheme == "https")
      http.read_timeout = @timeout
      http.open_timeout = @timeout

      res = http.request(req)
      raise Error, "HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    rescue URI::InvalidURIError => e
      raise Error, "Invalid endpoint URI: #{e.message}"
    rescue => e
      raise Error, e.message
    end
  end
end
