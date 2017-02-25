require 'dentaku/tokenizer'

describe Dentaku::Tokenizer do
  let(:tokenizer) { described_class.new }

  it 'handles an empty expression' do
    expect(tokenizer.tokenize('')).to be_empty
  end

  it 'tokenizes addition' do
    tokens = tokenizer.tokenize('1+1')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([1, :add, 1])
  end

  it 'tokenizes unary minus' do
    tokens = tokenizer.tokenize('-5')
    expect(tokens.map(&:category)).to eq([:operator, :numeric])
    expect(tokens.map(&:value)).to eq([:negate, 5])

    tokens = tokenizer.tokenize('(-5)')
    expect(tokens.map(&:category)).to eq([:grouping, :operator, :numeric, :grouping])
    expect(tokens.map(&:value)).to eq([:open, :negate, 5, :close])

    tokens = tokenizer.tokenize('if(-5 > x, -7, -8) - 9')
    expect(tokens.map(&:category)).to eq([
      :function, :grouping,                                      # if(
      :operator, :numeric, :comparator, :identifier, :grouping,  # -5 > x,
      :operator, :numeric, :grouping,                            # -7,
      :operator, :numeric, :grouping,                            # -8)
      :operator, :numeric                                        # - 9
    ])
    expect(tokens.map(&:value)).to eq([
      :if, :open,                   # if(
      :negate, 5, :gt, 'x', :comma, # -5 > x,
      :negate, 7, :comma,           # -7,
      :negate, 8, :close,           # -8)
      :subtract, 9                  # - 9
    ])
  end

  it 'tokenizes comparison with =' do
    tokens = tokenizer.tokenize('number = 5')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['number', :eq, 5])
  end

  it 'tokenizes comparison with alternate ==' do
    tokens = tokenizer.tokenize('number == 5')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['number', :eq, 5])
  end

  it 'tokenizes bitwise OR' do
    tokens = tokenizer.tokenize('2 | 3')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([2, :bitor, 3])
  end

  it 'tokenizes bitwise AND' do
    tokens = tokenizer.tokenize('2 & 3')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([2, :bitand, 3])
  end

  it 'ignores whitespace' do
    tokens = tokenizer.tokenize('1     / 1     ')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([1, :divide, 1])
  end

  it 'tokenizes power operations in simple expressions' do
    tokens = tokenizer.tokenize('10 ^ 2')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([10, :pow, 2])
  end

  it 'tokenizes power operations in complex expressions' do
    tokens = tokenizer.tokenize('0 * 10 ^ -5')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric, :operator, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([0, :multiply, 10, :pow, :negate, 5])
  end

  it 'handles floating point operands' do
    tokens = tokenizer.tokenize('1.5 * 3.7')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([1.5, :multiply, 3.7])
  end

  it 'does not require leading zero' do
    tokens = tokenizer.tokenize('.5 * 3.7')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([0.5, :multiply, 3.7])
  end

  it 'accepts arbitrary identifiers' do
    tokens = tokenizer.tokenize('sea_monkeys > 1500')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['sea_monkeys', :gt, 1500])
  end

  it 'recognizes double-quoted strings' do
    tokens = tokenizer.tokenize('animal = "giraffe"')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :string])
    expect(tokens.map(&:value)).to eq(['animal', :eq, 'giraffe'])
  end

  it 'recognizes single-quoted strings' do
    tokens = tokenizer.tokenize("animal = 'giraffe'")
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :string])
    expect(tokens.map(&:value)).to eq(['animal', :eq, 'giraffe'])
  end

  it 'recognizes binary minus operator' do
    tokens = tokenizer.tokenize('2 - 3')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([2, :subtract, 3])
  end

  it 'recognizes unary minus operator applied to left operand' do
    tokens = tokenizer.tokenize('-2 + 3')
    expect(tokens.map(&:category)).to eq([:operator, :numeric, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([:negate, 2, :add, 3])
  end

  it 'recognizes unary minus operator applied to right operand' do
    tokens = tokenizer.tokenize('2 - -3')
    expect(tokens.map(&:category)).to eq([:numeric, :operator, :operator, :numeric])
    expect(tokens.map(&:value)).to eq([2, :subtract, :negate, 3])
  end

  it 'matches "<=" before "<"' do
    tokens = tokenizer.tokenize('perimeter <= 7500')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['perimeter', :le, 7500])
  end

  it 'matches "and" for logical expressions' do
    tokens = tokenizer.tokenize('octopi <= 7500 AND sharks > 1500')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric, :combinator, :identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['octopi', :le, 7500, :and, 'sharks', :gt, 1500])
  end

  it 'matches "or" for logical expressions' do
    tokens = tokenizer.tokenize('size < 3 or admin = 1')
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric, :combinator, :identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['size', :lt, 3, :or, 'admin', :eq, 1])
  end

  it 'detects unbalanced parentheses' do
    expect { tokenizer.tokenize('(5+3') }.to raise_error(Dentaku::TokenizerError, /too many opening parentheses/)
    expect { tokenizer.tokenize(')')    }.to raise_error(Dentaku::TokenizerError, /too many closing parentheses/)
  end

  it 'recognizes identifiers that share initial substrings with combinators' do
    tokens = tokenizer.tokenize('andover < 10')
    expect(tokens.length).to eq(3)
    expect(tokens.map(&:category)).to eq([:identifier, :comparator, :numeric])
    expect(tokens.map(&:value)).to eq(['andover', :lt, 10])
  end

  it 'tokenizes TRUE and FALSE literals' do
    tokens = tokenizer.tokenize('true and false')
    expect(tokens.length).to eq(3)
    expect(tokens.map(&:category)).to eq([:logical, :combinator, :logical])
    expect(tokens.map(&:value)).to eq([true, :and, false])

    tokens = tokenizer.tokenize('true_lies and falsehoods')
    expect(tokens.length).to eq(3)
    expect(tokens.map(&:category)).to eq([:identifier, :combinator, :identifier])
    expect(tokens.map(&:value)).to eq(['true_lies', :and, 'falsehoods'])
  end

  it 'tokenizes Time literals' do
    tokens = tokenizer.tokenize('2017-01-01 2017-01-2 2017-1-03 2017-01-04 12:23:42 2017-1-5 1:2:3 2017-1-06 1:02:30 2017-01-07 12:34:56 Z 2017-01-08 1:2:3 +0800')
    expect(tokens.length).to eq(8)
    expect(tokens.map(&:category)).to eq([:datetime, :datetime, :datetime, :datetime, :datetime, :datetime, :datetime, :datetime])
    expect(tokens.map(&:value)).to eq([
      Time.local(2017, 1, 1).to_datetime,
      Time.local(2017, 1, 2).to_datetime,
      Time.local(2017, 1, 3).to_datetime,
      Time.local(2017, 1, 4, 12, 23, 42).to_datetime,
      Time.local(2017, 1, 5, 1, 2, 3).to_datetime,
      Time.local(2017, 1, 6, 1, 2, 30).to_datetime,
      Time.utc(2017, 1, 7, 12, 34, 56).to_datetime,
      Time.new(2017, 1, 8, 1, 2, 3, "+08:00").to_datetime
    ])
  end

  describe 'functions' do
    it 'include IF' do
      tokens = tokenizer.tokenize('if(x < 10, y, z)')
      expect(tokens.length).to eq(10)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :identifier, :comparator, :numeric, :grouping, :identifier, :grouping, :identifier, :grouping])
      expect(tokens.map(&:value)).to eq([:if, :open, 'x', :lt, 10, :comma, 'y', :comma, 'z', :close])
    end

    it 'include ROUND/UP/DOWN' do
      tokens = tokenizer.tokenize('round(8.2)')
      expect(tokens.length).to eq(4)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:round, :open, BigDecimal.new('8.2'), :close])

      tokens = tokenizer.tokenize('round(8.75, 1)')
      expect(tokens.length).to eq(6)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :grouping, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:round, :open, BigDecimal.new('8.75'), :comma, 1, :close])

      tokens = tokenizer.tokenize('ROUNDUP(8.2)')
      expect(tokens.length).to eq(4)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:roundup, :open, BigDecimal.new('8.2'), :close])

      tokens = tokenizer.tokenize('RoundDown(8.2)')
      expect(tokens.length).to eq(4)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:rounddown, :open, BigDecimal.new('8.2'), :close])
    end

    it 'include NOT' do
      tokens = tokenizer.tokenize('not(8 < 5)')
      expect(tokens.length).to eq(6)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :comparator, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:not, :open, 8, :lt, 5, :close])
    end

    it 'handles whitespace after function name' do
      tokens = tokenizer.tokenize('not (8 < 5)')
      expect(tokens.length).to eq(6)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :comparator, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:not, :open, 8, :lt, 5, :close])
    end

    it 'can end with a bang' do
      tokens = tokenizer.tokenize('exp!(5 * 3)')
      expect(tokens.length).to eq(6)
      expect(tokens.map(&:category)).to eq([:function, :grouping, :numeric, :operator, :numeric, :grouping])
      expect(tokens.map(&:value)).to eq([:exp!, :open, 5, :multiply, 3, :close])
    end
  end
end
