require "test_helper"

require "uri"

describe Hugs::Client do
  before do
    @uri      = URI::HTTP.build :host => "example.com", :path => "/"
    @client   = Hugs::Client.new :host => @uri.host

    WebMock.reset!
  end

  describe "verbs" do
    it "supports HTTP Get" do
      must_support_http_get
    end

    it "supports HTTP Delete" do
      must_support_http_delete
    end

    it "supports HTTP Head" do
      must_support_http_head
    end

    it "supports HTTP Post" do
      must_support_http_post
    end

    it "supports HTTP Put" do
      must_support_http_put
    end
  end

  describe "path" do
    it "supports a query string" do
      stub_request(:get, @uri.to_s).with:query => { "foo" => "bar" }

      @client.get @uri.path, :query => "foo=bar"

      assert_requested :get, @uri.to_s, :query => { "foo" => "bar" }
    end
  end

  describe "headers" do
    describe "json" do
      it "adds Accept header" do
        must_have_headers_for_get :json
      end

      it "adds Content-Type header" do
        must_have_headers_for_put :json
        must_have_headers_for_post :json
      end
    end

    describe "xml" do
      before do
        @client = Hugs::Client.new :host => @uri.host, :type => :xml
      end

      it "adds Accept header" do
        must_have_headers_for_get :xml
      end

      it "adds Content-Type header" do
        must_have_headers_for_put :xml
        must_have_headers_for_post :xml
      end
    end

    describe "override :headers per request" do
      before do
        @client = Hugs::Client.new(
          :host => @uri.host
        )
      end

      it "adds headers" do
        must_have_headers_for :get, { :headers => { "foo" => "bar" } }, "foo" => "bar"
      end

      it "overrides default headers" do
        must_have_headers_for :get, { :headers => { "Accept" => "foo bar" } }, "Accept" => "foo bar"
      end
    end

    describe "override :type per request" do
      before do
        @client = Hugs::Client.new(
          :host => @uri.host
        )
      end

      it "adds Accept header" do
        must_have_headers_for_get :xml, :type => :xml
      end

      it "adds Content-Type header" do
        must_have_headers_for_put :xml, :type => :xml
        must_have_headers_for_post :xml, :type => :xml
      end

      it "doesn't parse body" do
        stub_request(:get, @uri.to_s).to_return :body => "raw body"

        response = @client.get @uri.path, :type => :none

        response.body.must_equal "raw body"
      end
    end
  end

  describe "authentication" do
    before do
      @uri.userinfo = "user:credentials"
      @client = Hugs::Client.new(
        :host     => @uri.host,
        :user     => "user",
        :password => "credentials"
      )
    end

    it "uses Basic Authentication when initialized with :user and :password" do
      stub_request :get, @uri.to_s

      @client.get @uri.path

      assert_requested :get, @uri.to_s
    end
  end

  describe "parse body" do
    describe "json" do
      it "parses the body" do
        stub_request(:get, @uri.to_s).to_return :body => '{"foo":"bar"}'

        response = @client.get @uri.path

        response.body['foo'].must_equal "bar"
      end
    end

    describe "xml" do
      before do
        @client = Hugs::Client.new :host => @uri.host, :type => :xml
      end

      it "parses the body" do
        stub_request(:get, @uri.to_s).to_return :body => "<foo>bar</foo>"

        response = @client.get @uri.path

        response.body.xpath('foo').text.must_equal "bar"
      end
    end

    describe "none" do
      before do
        @client = Hugs::Client.new :host => @uri.host, :type => :none
      end

      it "doesn't parse body" do
        stub_request(:get, @uri.to_s).to_return :body => "raw body"

        response = @client.get @uri.path, :type => :none

        response.body.must_equal "raw body"
      end
    end
  end

  describe "encode body" do
    describe "json" do
      it "encodes the body" do
        stub_request :post, @uri.to_s

        @client.post @uri.path, :body => { :foo => :bar }

        assert_requested :post, @uri.to_s, :body => '{"foo":"bar"}'
      end
    end

    describe "xml" do
      before do
        @client = Hugs::Client.new :host => @uri.host, :type => :xml
      end

      it "does not encode the body" do
        stub_request :post, @uri.to_s

        @client.post @uri.path, :body => "foo bar"

        assert_requested :post, @uri.to_s, :body => "foo bar"
      end
    end
  end

  describe "upload" do
    describe "chunked" do
      before do
        @upload = {
          :upload => { :file => "/dev/null" }
        }

        @upload_with_headers = {
          :upload => {
            :file    => "/dev/null",
            :headers => { "Accept" => "foo bar" }
          }
        }
      end

      it "has headers" do
        must_have_headers_for :post, @upload, {
          "Content-Type"      => "application/octet-stream",
          ###"Content-Length"    => "0",
          "Transfer-Encoding" => "chunked"
        }
      end

      it "overrides default headers" do
        must_have_headers_for :post, @upload_with_headers, "Accept" => "foo bar"
      end

      it "has chunked body" do
        #stub_request :post, @uri.to_s

        #@client.post @uri.path, @upload

        #assert_requested verb, @uri.to_s, :headers => headers
      end
    end
  end

  describe "debug" do
    before do
      WebMock.allow_net_connect!
    end

    it "outputs net/http debug data" do
      out, _ = capture_io {
        client = Hugs::Client.new :host => "gist.github.com", :debug => true

        client.get "/api/v1/json/374130"
      }

      out.wont_be_empty
    end

    it "does not output net/http debug data" do
      out, _ = capture_io {
        client = Hugs::Client.new :host => "gist.github.com"

        client.get "/api/v1/json/374130"
      }

      out.must_be_empty
    end
  end

  def must_support_http_delete
    must_support_http :delete
  end

  def must_support_http_get
    must_support_http :get
  end

  def must_support_http_head
    must_support_http :head
  end

  def must_support_http_post
    must_support_http :post
  end

  def must_support_http_put
    must_support_http :put
  end

  def must_support_http verb
    stub_request verb, @uri.to_s
    @client.send verb, @uri.path

    assert_requested verb, @uri.to_s
  end

  def must_have_headers_for_get type, options = {}
    must_have_headers_for :get, options, "Accept" => ["*/*", "application/#{type}"]
  end

  def must_have_headers_for_put type, options = {}
    must_have_headers_for :put, options, "Content-Type" => "application/#{type}"
  end

  def must_have_headers_for_post type, options = {}
    must_have_headers_for :post, options, "Content-Type" => "application/#{type}"
  end

  def must_have_headers_for verb, options, headers
    stub_request verb, @uri.to_s

    @client.send verb, @uri.path, options

    assert_requested verb, @uri.to_s, :headers => headers
  end
end
