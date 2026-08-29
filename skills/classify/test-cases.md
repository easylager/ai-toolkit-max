# Classify Strategy Output - Test Cases

## Case 1: Simple Task - Fix typo in README

**Task Description:**
```
Fix the typo in line 42 of README.md where "reccomend" should be "recommend"
```

**Expected Strategy Output:**
```yaml
strategy:
  state_required: false
  research_required: false
  clarification_required: false
  planning_required: false
  verification_level: standard
```

**Expected Workflow:**
```
implement → verify
```

---

## Case 2: Medium Task - Add logging to error handler

**Task Description:**
```
Add structured logging to the error handler middleware in the API server. 
We need to log error type, status code, and request ID for debugging.
```

**Expected Strategy Output:**
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - existing error handler implementation
    - current logging patterns in the codebase
    - middleware structure
  clarification_required: true
  planning_required: true
  verification_level: standard
```

**Expected Workflow:**
```
research → clarify → plan → implement → verify
```

---

## Case 3: Complex Task - Refactor authentication system

**Task Description:**
```
Refactor the authentication system from session-based to JWT tokens.
This affects login flow, token refresh, logout, and all API endpoints that require auth.
Need to maintain backwards compatibility during migration.
```

**Expected Strategy Output:**
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - current session-based auth implementation
    - token validation and refresh patterns
    - affected endpoints and flows
    - backwards compatibility requirements
  clarification_required: true
  planning_required: true
  verification_level: elevated
```

**Expected Workflow:**
```
research → clarify → plan → implement → review → verify
```

---

## Case 4: Low Complexity but High Uncertainty - Add feature flag for feature X

**Task Description:**
```
Add a feature flag to enable/disable the new recommendation engine behind a toggle.
The flag should be controlled via environment variables.
```

**Expected Strategy Output:**
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - how the recommendation engine works
    - existing feature flag patterns
    - where to insert the conditional logic
  clarification_required: true
  planning_required: false
  verification_level: standard
```

**Expected Workflow:**
```
research → clarify → implement → verify
```

---

## Case 5: High Risk but Low Complexity - Add payment processing

**Task Description:**
```
Integrate Stripe payment processing for one-time purchases.
Handle success, error, and webhook callbacks from Stripe.
```

**Expected Strategy Output:**
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - Stripe API integration patterns
    - existing payment handling (if any)
    - webhook security patterns
  clarification_required: true
  planning_required: true
  verification_level: elevated
```

**Expected Workflow:**
```
research → clarify → plan → implement → review → verify
```

**Note:** Even though complexity is low, risk (financial transactions, security) and external dependencies (Stripe API) push this to elevated verification.

---

## Testing Process

1. Run `/ai-toolkit-max:classify` on each test case description
2. Compare actual output against expected output
3. Pay special attention to:
   - Does research_required match reality?
   - Are research_areas conceptual hints, not invented file/class names?
   - Does verification_level reflect the actual risk?
   - Is the workflow chain minimal but sufficient?
4. Document any mismatches and refine rules if needed
