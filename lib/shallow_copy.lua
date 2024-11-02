function shallow_copy(source_table)
  local dest_table = {}
  for key, value in pairs(source_table) do
    dest_table[key] = value
  end
  return dest_table
end
