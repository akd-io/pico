local myTable = { 1, 2, 3, text = "world!" }
setmetatable(myTable, {
  __call = function(self)
    print("Hello " .. self.text)
  end
})
myTable()
