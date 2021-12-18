# frozen_string_literal: true

# I guess Ruby has to make up for a non-existent type system with insane rules about
# the "complexity" of the code you're allowed to write. Apparently a function 13 lines
# long is too long, and case...when statements are extremely complex.

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Style/Documentation

require 'bitset'

class Bitset
  def slice(range)
    select_bits range.to_a
  end
end

class LiteralValue
  TYPE_ID = 4

  def initialize(version, value, length)
    @version = version
    @value = value
    @length = length
  end

  attr_accessor :version, :value, :length

  def self.parse(set, index)
    start_index = index

    version = set.slice(index..index + 2).to_s.to_i(2)
    type_id = set.slice(index + 3..index + 5).to_s.to_i(2)
    raise "Invalid type_id for literal value: #{type_id}" if type_id != TYPE_ID

    parts = []

    index += 6
    last_group = false
    until last_group || index > set.size
      last_group = true unless set[index]

      parts.append set.slice(index + 1..index + 4).to_s
      index += 5
    end

    value = parts.join('').to_i(2)

    LiteralValue.new(version, value, index - start_index)
  end
end

class Operator
  def initialize(version, type_id, packets, length)
    @version = version
    @type_id = type_id
    @packets = packets
    @length = length
  end

  attr_accessor :version, :type_id, :packets, :length

  def self._read_length(set, index, length)
    set.slice(index..index + length).to_s.to_i(2)
  end

  def self.parse(set, index)
    start_index = index

    version = set.slice(index..index + 2).to_s.to_i(2)
    type_id = set.slice(index + 3..index + 5).to_s.to_i(2)

    length_is_bits = !set[index + 6]
    if length_is_bits
      length = _read_length(set, index + 7, 14)
      index += 7 + 15
    else
      length = _read_length(set, index + 7, 10)
      index += 7 + 11
    end

    packets = []

    counter = 0
    while length_is_bits ? counter < length : packets.size < length
      p = parse_packet(set, index)
      break if p.nil?

      counter += p.length
      index += p.length
      packets.append p
    end

    Operator.new(version, type_id, packets, index - start_index)
  end

  # fun fact, rubocop considers this to be an overly complex function.
  def value
    case type_id
    when 0 # sum
      packets.map(&:value).sum
    when 1 # product
      packets.map(&:value).inject(:*)
    when 2 # min
      packets.map(&:value).min
    when 3 # max
      packets.map(&:value).max
    when 5 # greater than
      packets[0].value > packets[1].value ? 1 : 0
    when 6 # less than
      packets[0].value < packets[1].value ? 1 : 0
    when 7 # equal to
      packets[0].value == packets[1].value ? 1 : 0
    else
      raise "Unknown type: #{type_id}"
    end
  end
end

def parse_packet(set, index)
  return nil if set.slice(index..set.size - 1).to_s =~ /^0+$/

  type_id = set.slice(index + 3..index + 5).to_s.to_i(2)

  case type_id
  when LiteralValue::TYPE_ID
    LiteralValue.parse(set, index)
  else
    Operator.parse(set, index)
  end
end

def print_packet(packet, indent)
  if packet.instance_of?(LiteralValue)
    puts "#{indent}Value[v#{packet.version}] -> #{packet.value}"
  elsif packet.instance_of?(Operator)
    puts "#{indent}Operator[v#{packet.version}, #{packet.type_id}] ->"
    packet.packets.each do |p|
      print_packet(p, "#{indent}    ")
    end
  end
end

input = File.open(ARGV[0], &:readline)

# .hex throws away leading 0s
# Ruby's .hex omits leading zeros, don't know enough about ruby to get around that
# So just do it manually because it's easy
conversion = {
  '0' => '0000',
  '1' => '0001',
  '2' => '0010',
  '3' => '0011',
  '4' => '0100',
  '5' => '0101',
  '6' => '0110',
  '7' => '0111',
  '8' => '1000',
  '9' => '1001',
  'A' => '1010',
  'B' => '1011',
  'C' => '1100',
  'D' => '1101',
  'E' => '1110',
  'F' => '1111'
}

set = Bitset.from_s input.chars.map { |c| conversion[c] }.join('')

packet = parse_packet(set, 0)
print_packet(packet, '')

puts
# noinspection RubyNilAnalysis
puts packet.value
