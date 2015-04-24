module Hugs
  module Errors
    class Error < StandardError; end

    class HTTPStatusError < Error
      attr_accessor :response

      def initialize msg, response
        @response = response
        super msg
      end
    end

    ##
    # Taken from geemus:excon/lib/excon/errors.rb

    class BadRequest < HTTPStatusError; end                   # 400
    class Unauthorized < HTTPStatusError; end                 # 401
    class PaymentRequired < HTTPStatusError; end              # 402
    class Forbidden < HTTPStatusError; end                    # 403
    class NotFound < HTTPStatusError; end                     # 404
    class MethodNotAllowed < HTTPStatusError; end             # 405
    class NotAcceptable < HTTPStatusError; end                # 406
    class ProxyAuthenticationRequired < HTTPStatusError; end  # 407
    class RequestTimeout < HTTPStatusError; end               # 408
    class Conflict < HTTPStatusError; end                     # 409
    class Gone < HTTPStatusError; end                         # 410
    class LengthRequired < HTTPStatusError; end               # 411
    class PreconditionFailed < HTTPStatusError; end           # 412
    class RequestEntityTooLarge < HTTPStatusError; end        # 413
    class RequestURITooLong < HTTPStatusError; end            # 414
    class UnsupportedMediaType < HTTPStatusError; end         # 415
    class RequestedRangeNotSatisfiable < HTTPStatusError; end # 416
    class ExpectationFailed < HTTPStatusError; end            # 417
    class UnprocessableEntity < HTTPStatusError; end          # 422
    class InternalServerError < HTTPStatusError; end          # 500
    class NotImplemented < HTTPStatusError; end               # 501
    class BadGateway < HTTPStatusError; end                   # 502
    class ServiceUnavailable < HTTPStatusError; end           # 503
    class GatewayTimeout < HTTPStatusError; end               # 504

    class HTTP
      def initialize options
        @raise_errors = options[:raise_errors]

        initialize_errors
      end

      def on response
        case response.code
          when @raise_errors && %r{^[45]{1}[0-9]{2}$} ; raise_for(response)
        end

        response
      end

    private
      def raise_for response
        error, message = @errors[response.code.to_i]

        raise error.new message, response
      end

      def initialize_errors
        @errors ||= {
          400 => [Hugs::Errors::BadRequest, 'Bad Request'],
          401 => [Hugs::Errors::Unauthorized, 'Unauthorized'],
          402 => [Hugs::Errors::PaymentRequired, 'Payment Required'],
          403 => [Hugs::Errors::Forbidden, 'Forbidden'],
          404 => [Hugs::Errors::NotFound, 'Not Found'],
          405 => [Hugs::Errors::MethodNotAllowed, 'Method Not Allowed'],
          406 => [Hugs::Errors::NotAcceptable, 'Not Acceptable'],
          407 => [Hugs::Errors::ProxyAuthenticationRequired, 'Proxy Authentication Required'],
          408 => [Hugs::Errors::RequestTimeout, 'Request Timeout'],
          409 => [Hugs::Errors::Conflict, 'Conflict'],
          410 => [Hugs::Errors::Gone, 'Gone'],
          411 => [Hugs::Errors::LengthRequired, 'Length Required'],
          412 => [Hugs::Errors::PreconditionFailed, 'Precondition Failed'],
          413 => [Hugs::Errors::RequestEntityTooLarge, 'Request Entity Too Large'],
          414 => [Hugs::Errors::RequestURITooLong, 'Request-URI Too Long'],
          415 => [Hugs::Errors::UnsupportedMediaType, 'Unsupported Media Type'],
          416 => [Hugs::Errors::RequestedRangeNotSatisfiable, 'Request Range Not Satisfiable'],
          417 => [Hugs::Errors::ExpectationFailed, 'Expectation Failed'],
          422 => [Hugs::Errors::UnprocessableEntity, 'Unprocessable Entity'],
          500 => [Hugs::Errors::InternalServerError, 'InternalServerError'],
          501 => [Hugs::Errors::NotImplemented, 'Not Implemented'],
          502 => [Hugs::Errors::BadGateway, 'Bad Gateway'],
          503 => [Hugs::Errors::ServiceUnavailable, 'Service Unavailable'],
          504 => [Hugs::Errors::GatewayTimeout, 'Gateway Timeout']
        }
      end
    end
  end
end
