require 'oauth2'

class ChApiService
  DEFAULT_API_URL = "https://api.companieshouse.gov.uk"
  DEFAULT_API_OPEN_TIMEOUT = 60
  DEFAULT_API_READ_TIMEOUT = 60
  API_MODE = :live

  attr_reader :api_key, :api_url

  def initialize()
    api_mode = (API_MODE == :live ? "" : "SANDBOX_")
    @api_key = ENV.fetch("API_#{api_mode}KEY")
    raise ArgumentError, "API #{api_mode} key is missing" unless @api_key

    @api_url = URI(ENV.fetch("API_#{api_mode}URL") || DEFAULT_API_URL)
    raise ArgumentError, "HTTPS connection required" if @api_url.scheme != "https"

    @open_timeout = (ENV.fetch("API_OPEN_TIMEOUT") || DEFAULT_API_OPEN_TIMEOUT).to_i
    @read_timeout = (ENV.fetch("API_READ_TIMEOUT") || DEFAULT_API_READ_TIMEOUT).to_i
  end

  def end_connection
    @connection.finish if @connection&.started?
  end

  def company(id)
    request("company/#{id}", {})
  end

  def company_search(query, items_per_page: 1000, start_index: 0)
    request("search/companies", { q: query, items_per_page: items_per_page, start_index: start_index }.compact)
  end

  def alphabetic_company_search(query, items_per_page: nil, start_index: nil)
    request("alphabetic-search/companies", { q: query, items_per_page: items_per_page, start_index: start_index }.compact)
  end

  def connection
    @connection ||= Net::HTTP.new(@api_url.host, @api_url.port).tap do |conn|
      conn.use_ssl = true
      conn.open_timeout = @open_timeout
      conn.read_timeout = @read_timeout
    end
  end

  def request(path, params = {})
    uri = URI.join(@api_url, path)
    uri.query = URI.encode_www_form(params)
    resp = request_resource(uri)

    begin
      parse_api_response(resp)
    rescue StandardError => e
      raise e
    end
  end

  private

  def request_resource(uri)
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(@api_key, "")
    connection.request req
  end

  def parse_api_response(response)
    case response.code
    when "200"
      JSON[response.body]
    when "302" then { 'location': response["location"] }
    when "401"
      raise ArgumentError, "Authentication error"
    when "404"
      raise ArgumentError, "NotFoundError error"
    when "429"
      raise ArgumentError, "API rate limit exceeded"
    when "502"
      raise ArgumentError, "Bad API gateway"
    else
      raise ArgumentError, "Unknown API response"
    end
  end
end