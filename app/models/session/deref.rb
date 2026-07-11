class Session::Deref < Data.define(:store, :key)
  def read = store[key]
  def delete = store.delete(key)

  def write(value)
    store[key] = value
  end
end
