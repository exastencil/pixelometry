class System
  def self.process(entity); end
end

Dir[File.join(__dir__, 'systems', '*.rb')].each { |file| require file }
