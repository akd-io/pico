Potential other libs for React:

- Update/draw separation?
  - useDraw() hook only runs callback during \_draw().
  - useUpdate() hook only runs callback during \_update().
- React Form
  - useForm() hook
  - default values
  - validators
  - error handling
- React Table
  - headless table lib
  - Virtualized? Lol
- React Dom
  - Flex/Div/button-like primitives.
  - This lib should look at adding width/height to all components.
  - Each component should clip to its bounding box during render
  - With bounding boxes in place, it might be time to try and make react actually reactive. This is not render every frame. Only render on state/props changes.
