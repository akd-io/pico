local z = include("zod")

-- Test successful cases:
local myStringSchema = z.string()
local myObjectSchema = z.object({
  name = z.string(),
  age = z.string()
})
assert(myStringSchema.safeParse("hello").success, "Expected success")
assert(myObjectSchema.safeParse({ name = "John", age = "30" }).success, "Expected success")

-- Test failing safe case:
local safeFailingResult = myStringSchema.safeParse(123)
assert(not safeFailingResult.success, "Expected failure")
assert(safeFailingResult.error == "Expected string, got number", "Expected error message")

-- Test failing unsafe case throws:
local test = myStringSchema.parse(123) -- should throw an error

printh(test)
