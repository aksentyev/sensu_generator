module SensuGenerator
  class Exception < RuntimeError
  end

  class Error < Exception
  end

  class ApplicationException < Exception
  end

  class ApplicationError < Error
  end

  class RestarterError < Error
  end

  class GeneratorError < Error
  end

  class SensuServerError < Error
  end
end
