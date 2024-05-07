class Array
  def extract(&blk)
    ix = find_index(&blk)
    return nil unless ix
    val = self[ix]
    delete_at ix
    val
  end

  def avg
    sum.to_f / size
  end
end

