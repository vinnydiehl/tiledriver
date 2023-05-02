class Array
  %i[x y w h].each_with_index do |attr, i|
    define_method(attr) { self[i] }
    define_method("#{attr}=") { |value| self[i] = value }
  end
end

class Hash
  %i[x y w h].each do |attr|
    define_method(attr) { self[attr] }
    define_method("#{attr}=") { |value| self[attr] = value }
  end
end

class Object
  def deep_dup
    case self
    when Hash
      transform_values &:deep_dup
    when Array
      map &:deep_dup
    else
      dup
    end
  end
end
