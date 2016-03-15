class NodeArray
  attr_reader :array

  def initialize(array)
    @array = array.clone
  end

  def where(filter)
    raise(ArgumentError, 'Param must be a hash') unless filter.is_a?(Hash)
    # FIXME
    results = []
    @array.each do |item|
      item.args.each do |arg|
        next unless arg.is_a?(Hash)
        next if arg[filter.first[0]] != filter.first[1]
        results << item
      end
    end
    results
  end

  def find(filter)
    results = where(filter)
    results.count > 0 ? results.first : nil
  end

  def method_missing(method_symbol, *args, &_block)
    return @array.send(method_symbol, *args) if @array.respond_to?(method_symbol)
    super
  end
end
