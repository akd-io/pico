--[[
  Motion.p64
  This library tries to implement the most relevant features of the React
  Motion library for Picotron.
  See the original library here: https://motion.dev/

  REQUIREMENTS:
  - react.lua
]]

--! See Motion.p8 in the Pico8 folder for the original implementation and more documentation and TODOs.

function __initMotion()
  local SpringConfigContext = createContext({
    stiffness = 100,
    damping = 16.75, -- Prevents overshoot (at least with a half-pixel offset to prevent pixel-boundary oscillation)
    mass = 1
  })

  --- `useSprings` animates an array of numbers.
  --- @param animate table An array of numbers to animate.
  --- @param initial table? An array of numbers to start the animation from.
  --- @return table positions, table velocities The current positions and velocities of the springs.
  local function useSprings(animate, initial)
    assert(type(animate) == "table", "animate must be an array of numbers.")
    assert(type(initial) == "nil" or (type(initial) == "table" and type(initial[1]) == "number"),
      "initial must be nil or an array of numbers.")

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
      local acceleration = (-springConfig.stiffness * displacement - springConfig.damping * velocity) / springConfig
          .mass
      local newVelocity = velocity + acceleration * dt
      state.currentVelocities[i] = newVelocity
      state.currentPositions[i] = position + newVelocity * dt
    end

    return state.currentPositions, state.currentVelocities
  end

  local function useSpring(animate, initial)
    assert(type(animate) == "number", "animate must be a number.")
    assert(type(initial) == "nil" or type(initial) == "number", "initial must be nil or a number.")
    local positions, velocities = useSprings(
      { animate },
      initial and { initial } or nil
    )
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

-- Usage:
-- local useSprings, useSpring, useTransition, AnimatePresence, Motion = __initMotion()
