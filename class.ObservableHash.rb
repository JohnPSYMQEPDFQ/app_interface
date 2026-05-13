class ObservableHash
  include Enumerable

  def initialize(initial = {}, &on_change)
    @hash = initial.dup
    @on_change = on_change
  end

  #
  # --- core write operations ---
  #

  def []=(key, value)
    old = @hash[key]
    @hash[key] = value
    notify(:set, key, value, old)
    value
  end

  def delete(key)
    old = @hash.delete(key)
    notify(:delete, key, nil, old)
    old
  end

  def clear
    old = @hash.dup
    @hash.clear
    notify(:clear, nil, nil, old)
    self
  end

  def merge!(other)
    other.each do |k, v|
      self[k] = v   # ensures callback fires
    end
    self
  end

  #
  # --- read operations ---
  #

  def [](key)
    @hash[key]
  end

  def each(&block)
    @hash.each(&block)
  end

  def to_h
    @hash.dup
  end

  #
  # --- optional: expose some convenience ---
  #

  def keys
    @hash.keys
  end

  def values
    @hash.values
  end

  #
  # --- internal ---
  #

  private

  def notify(action, key, new_val, old_val)
    @on_change&.call(
      action: action,
      key: key,
      new: new_val,
      old: old_val,
      hash: @hash
    )
  end
end
