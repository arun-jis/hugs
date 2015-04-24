require "hugs/errors"

require "net/http/persistent"
require "uri"
require "nokogiri"
require "yajl"

module Hugs
  class Client
    MIME_TYPES = {
      :binary => "application/octet-stream",
      :json   => "application/json",
      :xml    => "application/xml",
      :none   => "text/plain"
    }.freeze

    CLASSES = [
      Net::HTTP::Delete,
      Net::HTTP::Get,
      Net::HTTP::Head,
      Net::HTTP::Post,
      Net::HTTP::Put
    ].freeze

    ##
    # Required options:
    #   +host+: A String with the host to connect.
    # Optional:
    #   +user+: A String containing the username for use in HTTP Basic Authentication.
    #   +pass+: A String containing the password for use in HTTP Basic Authentication.
    #   +port+: An Integer containing the port to connect.
    #   +scheme+: A String containing the HTTP scheme.
    #   +type+: A Symbol containing (:json or :xml) for automatic content-type parsing
    #           and encoding.
    #   +raises+: A boolean if HTTP 4xx and 5xx status codes should be raised.

    def initialize options
      @user    = options[:user]
      @pass    = options[:password]
      host     = options[:host]
      raises   = options[:raise_errors]
      port     = options[:port]   || 80
      scheme   = options[:scheme] || "http"
      @type    = options[:type]   || :json

      @http   = Net::HTTP::Persistent.new
      @errors = Errors::HTTP.new :raise_errors => raises
      @uri    = URI.parse "#{scheme}://#{options[:host]}:#{port}"

      @http.debug_output = $stdout if options[:debug]
    end

    ##
    # Perform an HTTP Delete, Head, Get, Post, or Put.

    CLASSES.each do |clazz|
      verb = clazz.to_s.split("::").last.downcase

      define_method verb do |*args|
        path   = args[0]
        params = args[1] || {}

        response_for clazz, path, params
      end
    end

    ##
    # :method: delete

    ##
    # :method: head

    ##
    # :method: get

    ##
    # :method: post

    ##
    # :method: put

  private
    ##
    # Worker method to be called by #delete, #get, #head, #post, or #put.
    #
    # +clazz+: A Net::HTTP request Object.
    # +path+: A String with the path to the HTTP resource.
    # +params+: A Hash containing the following keys:
    #   +:query+: A String with the format "foo=bar".
    #   +:type+: A Symbol with the mime_type.
    #   +:body+: A String containing the message body for Put and Post requests.
    #   +:upload+: A sub-Hash with the following keys:
    #     +:file+: The file to be HTTP chunked uploaded.
    #     +:headers+: A Hash containing additional HTTP headers.

    def response_for clazz, path, params
      request      = clazz.new path_with_query path, params[:query]
      request.body = encode params[:body], params[:type]

      handle_request request, params[:upload], params[:type], params[:headers] || {}
    end

    ##
    # Handles setting headers, performing the HTTP connection, parsing the
    # response, and checking for any response errors (if configured).
    #
    # +request+: A Net::HTTP request Object.
    # +:upload+: A sub-Hash with the following keys:
    #   +:file+: The file to be HTTP chunked uploaded.
    #   +:headers+: A Hash containing additional HTTP headers.
    # +:type+: A Symbol with the mime_type.
    # +:headers+: A Hash containing additional HTTP headers.

    def handle_request request, upload, type, headers
      handle_uploads request, upload, type
      handle_headers request, upload, type, headers

      response      = @http.request @uri, request
      response.body = parse response.body, type

      finish_uploads request

      @errors.on response
    end

    ##
    # Handle chunked uploads.
    #
    # +request+: A Net::HTTP request Object.
    # +upload+: A Hash with the following keys:
    #   +:file+: The file to be HTTP chunked uploaded.
    #   +:headers+: A Hash containing additional HTTP headers.
    # +:type+: A Symbol with the mime_type.

    def handle_uploads request, upload, type
      return unless upload

      request.body_stream = File.open upload[:file]
    end

    ##
    # Close filehandles used for chunked uploads.
    #
    # +request+: A Net::HTTP request Object.

    def finish_uploads request
      request.body_stream.close if request.body_stream
    end

    ##
    # Handles the setting of various default and custom headers.
    # Headers set in initialize can override all others.
    #
    # +request+: A Net::HTTP request Object.
    # +upload+: A Hash with the following keys:
    # +:type+: A Symbol with the mime_type.
    # +:headers+: A Hash containing additional HTTP headers.

    def handle_headers request, upload, type, headers
      request.basic_auth(@user, @pass) if requires_authentication?

      request.add_field "Accept", mime_type(type)
      request.add_field "Content-Type", mime_type(type) if requires_content_type? request

      headers.merge! chunked_headers upload
      headers.each do |header, value|
        request[header] = value
      end
    end

    ##
    # Setting of chunked upload headers.
    #
    # +upload+: A Hash with the following keys:
    #   +:file+: The file to be HTTP chunked uploaded.

    def chunked_headers upload
      return {} unless upload

      chunked_headers = {
        "Content-Type"      => mime_type(:binary),
        "Transfer-Encoding" => "chunked"
      }.merge upload[:headers] || {}
    end

    def path_with_query path, query
      [path, query].compact.join "?"
    end

    def parse data, type
      return unless data

      if is_json? type
        Yajl::Parser.parse data
      elsif is_xml? type
        Nokogiri::XML.parse data
      else
        data
      end
    end

    def encode body, type
      return unless body

      (is_json? type) ? (Yajl::Encoder.encode body) : body
    end

    def requires_authentication?
      @user && @pass
    end

    def requires_content_type? request
      [Net::HTTP::Post, Net::HTTP::Put].include? request.class
    end

    def is_xml? type
      (mime_type type) =~ %r{/xml$}
    end

    def is_json? type
      (mime_type type) =~ %r{/json$}
    end

    def mime_type type
      MIME_TYPES[type] || MIME_TYPES[@type]
    end
  end
end
