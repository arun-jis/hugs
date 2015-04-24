require "test_helper"

describe Hugs::Errors::HTTP do
  before do
    @errors_4xx = (400..417).to_a << 422
    @errors_5xx = (500..504).to_a
    @errors_all = @errors_4xx + @errors_5xx
    @uri        = URI::HTTP.build :host => "example.com"

    WebMock.reset!
  end

  describe "errors" do
    describe "does not raise" do
      before do
        @client = Hugs::Client.new :host => @uri.host
      end

      it "returns response" do
        @errors_all.each do |code|
          must_not_raise_on code
        end
      end
    end

    describe "raises" do
      before do
        @client = Hugs::Client.new :host => @uri.host, :raise_errors => true
      end

      it "returns exception" do
        @errors_all.each do |code|
          must_raise_on code
        end
      end
    end
  end

  def must_raise_on code
    stub_request(:get, @uri.to_s).to_return :status => [code, "error #{code}"]

    begin
      @client.get "/"
    rescue => e
      e.class.superclass.must_be_same_as Hugs::Errors::HTTPStatusError
      e.must_respond_to :response
      return
    end
    raise StandardError.new "did not raise expected exception"
  end

  def must_not_raise_on code
    stub_request(:get, @uri.to_s).to_return :status => [code, "error #{code}"]

    response = @client.get "/"

    response.code.must_equal code.to_s
  end
end
