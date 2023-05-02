class ArgsMock
  def grid
    @grid ||= ArgsGridMock.new
  end

  def outputs
    @outputs ||= OutputsMock.new
  end
end

class ArgsGridMock
  def w
    SCREEN_WIDTH
  end

  def h
    SCREEN_HEIGHT
  end
end

class OutputsMock
  def method_missing(_)
    @stream ||= OutputsArrayMock.new
  end
end

class OutputsArrayMock
  def <<(_)
    nil
  end
end

module GTK
  class << self
    def parse_xml_file(path)
      hash_to_element Hash.from_xml(File.open(path).read)
    end

    private

    # Close enough
    def hash_to_element(hash)
      element = { :type => :element, :name => nil, :children => [] }
      hash.each do |key, value|
        if value.is_a?(Hash)
          child = hash_to_element(value)
          child[:name] = key
          element[:children] << child
        elsif value.is_a?(Array)
          value.each do |item|
            child = hash_to_element(item)
            child[:name] = key
            element[:children] << child
          end
        elsif %w[ellipse point].include?(key)
          child = element.deep_dup
          child[:name] = key
          child[:children] = []
          element[:children] << child
        else
          element[:attributes] ||= {}
          element[:attributes][key] = value
        end
      end
      element
    end
  end
end

$gtk = GTK
