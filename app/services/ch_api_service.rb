require 'oauth2'

class ChApiService
  DEFAULT_API_URL = "https://api.companieshouse.gov.uk"
  DEFAULT_API_OPEN_TIMEOUT = 60
  DEFAULT_API_READ_TIMEOUT = 60
  API_MODE = :live

  def initialize()
    # API mode switch
    api_mode = (API_MODE == :live ? "" : "SANDBOX_")

    # get the proper API key
    @api_key = ENV.fetch("API_#{api_mode}KEY")

    # throw an error if there is no API key
    raise ArgumentError, "API #{api_mode} key is missing" unless @api_key

    # set the proper api_url, from ENV or default
    @api_url = URI(ENV.fetch("API_#{api_mode}URL") || DEFAULT_API_URL)

    # raise an error if the protocol is not https
    raise ArgumentError, "HTTPS connection required" if @api_url.scheme != "https"

    # set connection timeouts
    @open_timeout = (ENV.fetch("API_OPEN_TIMEOUT") || DEFAULT_API_OPEN_TIMEOUT).to_i
    @read_timeout = (ENV.fetch("API_READ_TIMEOUT") || DEFAULT_API_READ_TIMEOUT).to_i
  end

  # close the current connection
  def end_connection
    # close the connection
    @connection.finish if @connection&.started?
  end

  # search for company
  def company_search(query, items_per_page: 1000, start_index: 0)
    request("search/companies", { q: query, items_per_page: items_per_page, start_index: start_index }.compact)
  end

  # alphabetic search for company
  def alphabetic_company_search(query, items_per_page: nil, start_index: nil)
    request("alphabetic-search/companies", { q: query, items_per_page: items_per_page, start_index: start_index }.compact)
  end

  # create API connection
  def connection
    @connection ||= Net::HTTP.new(@api_url.host, @api_url.port).tap do |conn|
      conn.use_ssl = true
      conn.open_timeout = @open_timeout
      conn.read_timeout = @read_timeout
    end
  end

  # send the request
  def request(path, params = {})
    # create uri from api_url
    uri = URI.join(@api_url, path)

    # encode the params
    uri.query = URI.encode_www_form(params)

    # send the request
    resp = request_resource(uri)

    begin
      # parse request response
      parse_api_response(resp)

      # end the connection
      end_connection
    rescue StandardError => e
      raise e
    end
  end

  private

  def request_resource(uri)
    # build up the request
    req = Net::HTTP::Get.new(uri)

    # set the authentication
    req.basic_auth(@api_key, "")

    # send the request
    connection.request(req)
  end

  def parse_api_response(resp)
    # parse the response according to response status code
    case resp.code
    when "200"
      JSON[resp.body]
    when "401"
      raise ArgumentError, "Authentication error"
    when "404"
      raise ArgumentError, "NotFoundError error"
    when "429"
      raise ArgumentError, "API rate limit exceeded"
    else
      raise ArgumentError, "Unknown API response"
    end
  end
end