require 'spec_helper'
require 'dentaku/ast/functions/min'
require 'dentaku'

describe 'Dentaku::AST::Function::Min' do
  it 'returns the smallest numeric value in an array of Numeric values' do
    result = Dentaku('MIN(1, x, 1.8)', x: 2.3)
    expect(result).to eq 1
  end

  it 'returns the smallest value even if a String is passed' do
    result = Dentaku('MIN(1, x, 1.8)', x: '0.3')
    expect(result).to eq 0.3
  end

  it 'returns the smallest value even if an Array is passed' do
    result = Dentaku('MIN(1, x, 1.8)', x: [1.5, 0.3, 1.7])
    expect(result).to eq 0.3
  end
end
