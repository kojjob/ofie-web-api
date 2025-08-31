# Base query class for all query objects
class ApplicationQuery
  attr_reader :relation

  def initialize(relation = nil)
    @relation = relation || default_relation
  end

  def call
    @relation
  end

  # Chain multiple query methods
  def self.call(relation = nil)
    new(relation).call
  end

  protected

  # Override in subclasses to provide default relation
  def default_relation
    raise NotImplementedError, "Subclasses must implement default_relation"
  end

  # Common query helpers
  def paginate(page: 1, per_page: 20)
    @relation = @relation.page(page).per(per_page)
    self
  end

  def order_by(column, direction = :asc)
    @relation = @relation.order(column => direction)
    self
  end

  def includes(*associations)
    @relation = @relation.includes(*associations)
    self
  end

  def preload(*associations)
    @relation = @relation.preload(*associations)
    self
  end

  def joins(*associations)
    @relation = @relation.joins(*associations)
    self
  end

  def distinct
    @relation = @relation.distinct
    self
  end

  def limit(count)
    @relation = @relation.limit(count)
    self
  end

  # Apply multiple filters at once
  def apply_filters(filters = {})
    filters.each do |key, value|
      method_name = "filter_by_#{key}"
      if respond_to?(method_name, true)
        send(method_name, value) if value.present?
      end
    end
    self
  end
end