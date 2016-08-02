module SensuGenerator
  %w(ApplicationError RestarterError GeneratorError SensuServerError ClientError ServerError).each do |e|
    eval(
      %Q(
        class #{e} < StandardError
          def initialize(msg)
            Application.logger.error msg
          end
        end
      )
    )
  end
end

module Diplomat
  class PathNotFound < StandardError
    def initialize(*args)
      ::SensuGenerator::Application.logger.error "Could not connect to consul with provided url"
    end
  end
end
