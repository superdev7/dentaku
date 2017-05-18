require_relative '../function'

Dentaku::AST::Function.register(:rounddown, :numeric, lambda { |numeric, precision = 0|
  precision = precision.to_i
  tens = 10.0**precision
  result = (Dentaku::AST::Function.numeric(numeric) * tens).floor / tens
  precision <= 0 ? result.to_i : result
})
