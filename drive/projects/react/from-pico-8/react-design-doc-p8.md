# React.p8 Design Document

This is the design document for the React.p8 library for Pico-8 and Picotron.

## Table of contents

- [1 Elements](#1-elements)
- [2 Design choices](#2-design-choices)
  - [2.1 Elements](#21-elements)
    - [2.1.1 Element syntax](#211-element-syntax)
    - [2.1.2 Function syntax](#212-function-syntax)
  - [2.2 Keys](#22-keys)
    - [2.2.1 Element key](#221-element-key)
    - [2.2.2 Keys in props](#222-key-in-props)
    - [2.2.3 Key element wrappers](#223-key-element-wrappers)
  - [2.3 Props](#23-props)
    - [2.3.1 Named props](#231-named-props)
    - [2.3.2 Unnamed props](#232-unnamed-props)
    - [2.3.3 Comparison including keys](#233-comparison-including-keys)

## 1 Elements

In order to render React components, as they are specified by users, from top to bottom, parent to child, we need to build a representation of the UI tree.

We built this representation using elements; the building blocks of React.

Elements look like this:

```lua
{ Component }                             -- Simplest element
{ Component, prop1, prop2, prop2 }        -- Element with props
{ "key", Component }                      -- Element with key
{ "key", Component, prop1, prop2, prop2 } -- Element with key and props
```

## 2 Design choices

This section discusses different options available for the design of the React.p8 library.

### 2.1 Elements

This section discusses two possible alternatives to JSX.

#### 2.1.1 Element syntax

Example using [Element syntax](#211-element-syntax), [Element key](#221-element-key) and [Unnamed props](#232-unnamed-props):

```lua
{ "paragraph-key-1", Paragraph, "First paragraph" }
```

This is the simplest syntax from a code perspective. This is because React.p8 uses this Element syntax internally, and the effort to support this syntax, and its performance overhead, is practically none. It's also short on tokens.

#### 2.1.2 Function syntax

Example using [Function syntax](#212-function-syntax), [Key in props](#222-key-in-props) and [Named props](#231-named-props):

```lua
Paragraph({ key = "paragraph-key-1", text = "First paragraph" })
```

This can be simplified slightly using the table-variant of the single-argument function call syntactic sugar.

Example using [Function syntax](#212-function-syntax), [Key in props](#222-key-in-props) and [Named props](#231-named-props):

```lua
Paragraph{ key = "paragraph-key-1", text = "First paragraph" }
```

The rest of this document will use this variant when showcasing the Function syntax.

As described in the [Element syntax section](#211-element-syntax), the Function syntax needs to convert to Element syntax behind the scenes during rendering. As such, this syntax adds a performance overhead.

It will likely look cleaner and more readable to some users. And might even be familiar to devs using frameworks like Flutter. Apart from the performance overhead, it does however also add an extra layer of magic, and I'm not sure this is worth it.

The layer of magic stems from components using the Function syntax needing to be wrapped in a `component(renderFunc)` function. The `component` function return a function that converts the Function syntax to Element syntax, with the `renderFunc` simply passed on to the element.

One thing it does help with however, is more clearly separate surrounding array curly braces from the elements.

Compare this example using [Element syntax](#211-element-syntax) (and [Unnamed props](#232-unnamed-props)):

```lua
return {
  { Container, {
    { Header },
    { Body, {
      { Paragraph, "First paragraph" },
      { Paragraph, "Second paragraph" }
    }
  }
}
```

To this example using [Function syntax](#212-function-syntax) (and [Unnamed props](#232-unnamed-props)):

```lua
return {
  Container(
    Header(),
    Body(
      Paragraph("First paragraph"),
      Paragraph("Second paragraph")
    )
  )
}
```

It is much easier for the eyes to parse the braces if the Function syntax.

### 2.2 Keys

This section discusses three possible ways to specify keys for elements.

#### 2.2.1 Element key

This requires the [Element syntax](#211-element-syntax).

Example using [Element syntax](#211-element-syntax), [Element key](#221-element-key) and [Unnamed props](#232-unnamed-props):

```lua
{ "paragraph-key-1", Paragraph, "First paragraph" }
```

#### 2.2.2 Key in props

This requires the [Function syntax](#212-function-syntax) and [Named props](#231-named-props).

Example using [Function syntax](#212-function-syntax), [Key in props](#222-key-in-props) and [Named props](#231-named-props):

```lua
Paragraph{ key = "paragraph-key-1", text = "First paragraph" }
```

#### 2.2.3 Key element wrappers

This requires the [Function syntax](#212-function-syntax).

Example using [Function syntax](#212-function-syntax), [Key element wrappers](#223-key-element-wrappers) and [Unnamed props](#232-unnamed-props):

```lua
{ "paragraph-key-1", Paragraph("First paragraph") }
```

At first look, this syntax might look unproblematic. But let's introduce a couple more components, some with keys and some without.

Example using [Function syntax](#212-function-syntax), [Key element wrappers](#223-key-element-wrappers) and [Unnamed props](#232-unnamed-props):

```lua
{ "container-key", Container(
  Header(),
  Body(
    { "paragraph-key-1", Paragraph( "First paragraph" ) },
    Paragraph( "Second paragraph" ),
    { "paragraph-key-3", Paragraph( "Third paragraph" ) }
  )
) }
```

While an unusual case to have keyed and unkeyed elements at the same level, it's clear how this structure can become hard to parse, as elements will bounce between starting with a curly brace or a component name.

### 2.3 Props

This section discusses two possible ways to specify props for elements.

#### 2.3.1 Named props

Example using [Function syntax](#212-function-syntax) and [Named props](#231-named-props):

```lua
Container{
  topSlot = Header(),
  centerSlot = Body{
    Paragraph{ text = "First paragraph" },
    Paragraph{ text = "Second paragraph" }
  }
}
```

#### 2.3.2 Unnamed props

Example using [Function syntax](#212-function-syntax) and [Unnamed props](#232-unnamed-props):

```lua
Container(
  Header(),
  Body(
    Paragraph( "First paragraph" ),
    Paragraph( "Second paragraph" )
  )
)
```

#### 2.3.3 Comparison including keys

Example using [Function syntax](#212-function-syntax), [Key in props](#222-key-in-props) and [Named props](#231-named-props):

```lua
Container{
  key = "container-key",
  topSlot = Header(),
  centerSlot = Body{
    Paragraph{ key = "paragraph-key-1", text = "First paragraph" },
    Paragraph{ key = "paragraph-key-2", text = "Second paragraph" }
  }
}
```

Example using [Function syntax](#212-function-syntax), [Key element wrappers](#223-key-element-wrappers) and [Unnamed props](#232-unnamed-props):

```lua
{ "container-key", Container(
  Header(),
  Body(
    { "paragraph-key-1", Paragraph( "First paragraph" ) },
    { "paragraph-key-2", Paragraph( "Second paragraph" ) }
  )
) }
```

When adding keys, it becomes apparent, that the [Key in props](#222-key-in-props) approach helps the Named props approach achieve significantly nicer syntax than the Unnamed props approach.

TODO: In summary: unnamed props is a subset of named props. If we support unnamed props, named props are also supported. Let's use key-in-props. If we encounter a function element whose first argument is of the form `{ key = "string" }`, a table with a single key property on it ONLY, then we remove that whole first param before forwarding params to the component render function. If users don't like it props-object, they can just use the `{ key = "string" }` first param. We will also still support the base element syntax for perf/token optimization.
