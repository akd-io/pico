--[[
  Motion.p8
  This library tries to implement the most relevant features of the React
  Motion library for Pico-8.
  See the original library here: https://motion.dev/

  REQUIREMENTS:
  - react.lua
]]

--[[
  TODOs:
  - Support adding config to `useSpring`?. Like `useSpring(0, { stiffness: 300 })`
  - Support `useTransition`. Linear?, bezier?, frame-by-frame value array?
  - Support AnimatePresence.
  - Like Motion.Div, etc., support Motion wrappers for drawing functions.
    I.e. components that accept `initial`, `animate`, and `exit` props to
    animate draw function args.
    - Support all drawing functions: pset, sset, fset, print, cursor, color,
      cls, camera, circ, circfill, oval, ovalfill, line, rect, rectfill, pal,
      palt, spr, sspr, fillp, mset, map, tline.
    - Possible big brain: Consider making a single Motion component that just
      takes the drawing function as input as well as `initial`, `animate`, and
      `exit`.
      - Usage could look like:
          return { Motion, rect, {
            initial: { 0, 0, 10, 10 },
            animate: { 10, 10, 20, 20 },
            exit: { 20, 20, 30, 30 }
          } }
      - At second glance, would we really want motion rect in the output?
        There's no HTML forcing us to do this. We could implement the Motion
        component as a useMotion hook instead. This could look like:
          useMotion(rect, {
            initial: { 0, 0, 10, 10 },
            animate: { 10, 10, 20, 20 },
            exit: { 20, 20, 30, 30 }
          })
      - Pros for a Motion component over useMotion:
        - Can idiomatically be passed to components as children.
          - (But I guess this point is moot, isn't the question, what should be
            idiomatic?)
        - Keeping rendering to the output of the component, rather than
          rendering in a hook, might make react.p8 code more readable in the
          long run.
      - Pros for useMotion over a Motion component:
        - Can be composed in hooks.
        - Might be more performant than a component?
  - Possibly implement useContext in react.p8, and use that to set default
    animation settings, like spring config.
  - See if it's possible to release a pure Lua version and have this be a react
    wrapper.
    - I imagine we'll reach the fewest tokens in react-motion by baking not
      relying on another external implementation.
    - I should probably just release a `calcNextSpringPosition` function
]]

--[=[
function __initMotion()
  local SpringConfigContext = createContext({
    stiffness = 100,
    damping = 10,
    mass = 1
  })

  local function useSprings(animate, initial)
    assert(type(animate) == "table", "animate must be an array of numbers.")
    assert(type(initial) == "nil" or (type(initial) == "table" and type(initial[1]) == "number"), "initial must be nil or an array of numbers.")

    local state = useState(function()
      return {
        targetPositions = animate,
        currentPositions = initial or animate,
        currentVelocities = {}
      }
    end)

    assert(#state.currentPositions == #animate, "The length of animate must be constant.")

    state.targetPositions = animate

    local springConfig = useContext(SpringConfigContext)

    local dt = 1 / 60
    for i, targetPosition in ipairs(state.targetPositions) do
      local position = state.currentPositions[i]
      local velocity = state.currentVelocities[i] or 0
      local displacement = position - targetPosition
      local acceleration = (-springConfig.stiffness * displacement - springConfig.damping * velocity) / springConfig.mass
      local newVelocity = velocity + acceleration * dt
      state.currentVelocities[i] = newVelocity
      state.currentPositions[i] = position + newVelocity * dt
    end

    return state.currentPositions, state.currentVelocities
  end

  local function useSpring(animate, initial)
    assert(type(animate) == "table", "animate must be an array of function arguments.")
    assert(type(initial) == "nil" or type(initial) == "number", "initial must be nil or a number.")
    local initial = initial and { initial } or nil
    local positions, velocities = useSprings({ animate }, initial)
    return positions[1], velocities[1]
  end

  local function useTransition()
    assert(false, "useTransition is not implemented yet.")
  end

  local function AnimatePresence()
    assert(false, "AnimatePresence is not implemented yet.")
  end

  local function Motion(drawFunc, animate, initial)
    assert(type(drawFunc) == "function", "drawFunc must be a function.")
    assert(type(animate) == "table", "animate must be an array of function arguments.")

    --[[
      TODOs:
      - Make it possible to pass non-animated props to the drawFunc.
        - I think we might need to use props objects instead of props arrays here to achieve a nice API.
    ]]

    local currentArgs = useSprings(animate, initial)

    drawFunc(unpack(currentArgs))
  end

  return useSprings, useSpring, useTransition, AnimatePresence, Motion
end

local useSprings, useSpring, useTransition, AnimatePresence, Motion = __initMotion()
]=]
