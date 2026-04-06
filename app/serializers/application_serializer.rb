class ApplicationSerializer
  def self.render(resource, **options)
    if resource.respond_to?(:to_ary)
      resource.map { |item| new(item, **options).as_json }
    else
      new(resource, **options).as_json
    end
  end

  def initialize(resource, **options)
    @resource = resource
    @options = options
  end

  private

  attr_reader :resource, :options
end
