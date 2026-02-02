-- __ManisBossDemolisher__/scripts/tests/infrastructure/DeferredTestRunner.lua
-- ------------------------------------------------------------
-- Responsibility:
--   Deferred-capable test runner scoped to THIS mod's storage.
--   - Supports tick-crossing assertions without per-test nth_tick.
--   - Runs deferred tests SEQUENTIALLY (no parallel pending across tests).
--
-- Key policy:
--   - If a test schedules defer_in_ticks, the suite pauses immediately.
--   - The centralized pump resumes the suite only after the deferred test is resolved.
--
-- Notes:
--   - Does NOT modify __Manis_TestFramework__.
--   - Deferred callbacks and suite functions live in memory registry (not in storage).
-- ------------------------------------------------------------
local R = {}

local PREFIX = "[ManisTest] "
local STORAGE_KEY = "_mbd_deferred_tests"

local BaseAssert = require("__Manis_TestFramework__/scripts/test/TestRunner") -- for assert helpers

-- non-serialized registries
local _task_registry = {}  -- task_id -> fn(T)
local _suite_registry = {} -- suite_id -> {test_functions=table, names=array}

local _task_seq = 0

local function root()
  storage[STORAGE_KEY] = storage[STORAGE_KEY] or {}
  local r = storage[STORAGE_KEY]
  r.queue = r.queue or {}   -- array of {task_id, due_tick, suite_id, test_name}
  r.suites = r.suites or {} -- suite_id -> suite_state (serialized)
  r.seq = (r.seq or 0)      -- suite id seq
  return r
end

local function write_line(msg)
  log(PREFIX .. tostring(msg))
  if game and game.print then
    game.print(PREFIX .. tostring(msg))
  end
end

local function now_tick()
  return (game and game.tick) or 0
end

local function new_suite_id()
  local r = root()
  r.seq = r.seq + 1
  return tostring(r.seq)
end

local function make_T(suite_id, suite_name, test_name)
  local T = {}

  -- inherit assertion helpers
  for k, v in pairs(BaseAssert) do
    if type(v) == "function" and (k:find("^assert") == 1) then
      T[k] = v
    end
  end

  function T.defer_in_ticks(n, fn)
    if type(n) ~= "number" or n < 1 then
      error("FAIL: defer_in_ticks(n, fn): n must be >= 1")
    end
    if type(fn) ~= "function" then
      error("FAIL: defer_in_ticks(n, fn): fn must be function")
    end

    local r = root()
    local suite = r.suites and r.suites[suite_id]
    if not suite then
      error("FAIL: defer_in_ticks: suite state missing")
    end
    local tstate = suite.tests and suite.tests[test_name]
    if not tstate then
      error("FAIL: defer_in_ticks: test state missing")
    end

    -- One deferred block per test case (keeps execution model simple)
    if tstate.status == "pending" then
      error("FAIL: defer_in_ticks: already pending for this test (only one pending allowed)")
    end

    -- register callback in memory
    _task_seq = _task_seq + 1
    local task_id = tostring(_task_seq)
    _task_registry[task_id] = fn

    -- enqueue serialized task
    table.insert(r.queue, {
      task_id = task_id,
      due_tick = now_tick() + n,
      suite_id = suite_id,
      test_name = test_name
    })

    -- mark pending; suite pauses here (sequential model)
    tstate.status = "pending"
    suite.pending = 1
  end

  return T
end

local function suite_done(suite)
  return suite and suite.next_index and suite.names and (suite.next_index > #suite.names)
end

-- Execute tests sequentially until:
--   - a test becomes pending, or
--   - suite completes
local function run_until_pause_or_done(suite_id)
  local r = root()
  local suite = r.suites and r.suites[suite_id]
  if not suite or suite.ended then return end

  local reg = _suite_registry[suite_id]
  if not reg or not reg.test_functions then
    -- If registry is missing, we cannot continue. Mark as failed hard.
    suite.ended = true
    write_line(string.format("=== END SUITE: %s (Pass: %d, Fail: %d) ===",
      suite.suite_name, suite.passed or 0, (suite.failed or 0) + 1))
    r.suites[suite_id] = nil
    return
  end

  while true do
    if suite.pending and suite.pending > 0 then
      -- Paused on pending
      return
    end

    if suite_done(suite) then
      suite.ended = true
      write_line(string.format("=== END SUITE: %s (Pass: %d, Fail: %d) ===",
        suite.suite_name, suite.passed or 0, suite.failed or 0))
      r.suites[suite_id] = nil
      _suite_registry[suite_id] = nil
      return
    end

    local test_name = suite.names[suite.next_index]
    suite.next_index = suite.next_index + 1

    suite.tests[test_name] = { status = "running" }

    local T = make_T(suite_id, suite.suite_name, test_name)

    local ok, err = pcall(function()
      reg.test_functions[test_name](T)
    end)

    if ok then
      local status = suite.tests[test_name].status
      if status == "pending" then
        -- Sequential model: stop here and wait for pump to resolve
        write_line("  [PEND] " .. test_name)
        return
      else
        suite.tests[test_name].status = "passed"
        suite.passed = suite.passed + 1
        write_line("  [PASS] " .. test_name)
      end
    else
      suite.tests[test_name].status = "failed"
      suite.failed = suite.failed + 1
      write_line("  [FAIL] " .. test_name .. " :: " .. tostring(err))
      -- continue to next test (fail does not block suite)
    end
  end
end

-- Called by pump
function R._pump()
  local r = storage and storage[STORAGE_KEY]
  if not r or not r.queue or #r.queue == 0 then return end

  local tick = now_tick()
  local i = 1
  while i <= #r.queue do
    local task = r.queue[i]
    if task and task.due_tick <= tick then
      table.remove(r.queue, i)

      local suite = r.suites and r.suites[task.suite_id]
      local fn = _task_registry[task.task_id]
      _task_registry[task.task_id] = nil

      if suite and not suite.ended and suite.tests and suite.tests[task.test_name] then
        local tstate = suite.tests[task.test_name]
        local T = make_T(task.suite_id, suite.suite_name, task.test_name)

        local ok, err = pcall(function()
          if type(fn) ~= "function" then
            error("FAIL: deferred callback missing (registry cleared)")
          end
          fn(T)
        end)

        if ok then
          if tstate.status == "pending" then
            tstate.status = "passed"
            suite.passed = suite.passed + 1
            write_line("  [PASS] " .. task.test_name)
          end
        else
          if tstate.status == "pending" then
            tstate.status = "failed"
            suite.failed = suite.failed + 1
            write_line("  [FAIL] " .. task.test_name .. " :: " .. tostring(err))
          end
        end

        -- clear pending and resume suite
        suite.pending = 0
        run_until_pause_or_done(task.suite_id)
      end
    else
      i = i + 1
    end
  end
end

-- Run suite (sequential + deferred)
function R.run_suite(suite_name, test_functions)
  write_line("=== START SUITE: " .. suite_name .. " ===")

  local names = {}
  for name, _ in pairs(test_functions) do
    names[#names + 1] = name
  end
  table.sort(names)

  local suite_id = new_suite_id()
  local r = root()
  r.suites[suite_id] = {
    suite_name = suite_name,
    passed = 0,
    failed = 0,
    pending = 0,  -- 0 or 1 (sequential)
    ended = false,
    names = names,
    next_index = 1,
    tests = {},
  }

  _suite_registry[suite_id] = {
    test_functions = test_functions,
    names = names,
  }

  -- Run immediately until first pending or done
  run_until_pause_or_done(suite_id)

  -- If pending, print suite pending summary (one line)
  local suite = r.suites[suite_id]
  if suite and not suite.ended and suite.pending > 0 then
    write_line(string.format(
      "=== SUITE PENDING: %s (Pending: %d, Pass: %d, Fail: %d) ===",
      suite_name, suite.pending, suite.passed, suite.failed
    ))
  end
end

return R