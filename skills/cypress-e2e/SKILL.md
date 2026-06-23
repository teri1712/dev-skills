---
name: cypress-e2e
description: Writes Cypress E2E tests validating UI state based on API interface conditions, following strict naming conventions and regression-preventing assertions. Use when writing Cypress E2E test files or adding test cases.
---

# Cypress E2E Test Writer

This skill guides the creation of Cypress E2E tests that validate UI behavior and API integrations robustly.

## Core Mindset & Rules

1. **Page Reflection & API Interface Validation**: Validate pages reflect API state changes correctly (loading, empty, success, errors). Mock responses using `cy.intercept`.
2. **Naming Convention**: Test case descriptions must strictly follow the format:
   `it('should <result> when <something happens>', () => { ... })`
3. **Regression Prevention ("Facts")**: Design test assertions based on business requirements. These assertions are source-of-truth facts that prevent future regression when logic changes.
4. **Interactive Development Loop**: Continuously propose and refine test cases with the user. Suggest new test cases for confirmation at each turn.

## Workflow

1. **Gather API/UI Specs**: Identify the page component, API endpoints, mock payloads, and target states.
2. **Propose Test Cases**: Present the user with a list of candidate test cases using the `should...when...` naming scheme.
3. **Implement Cypress Tests**:
   - Write Cypress test files under `cypress/e2e/`.
   - Setup appropriate `cy.intercept` calls to handle mock inputs.
   - Assert page transitions and elements.
4. **Validate**: Run tests to ensure everything works properly.
5. **Suggest Next Steps**: Propose additional regression scenarios.

Refer to [e2e_mindset.md](file:///home/decade/Documents/dev-skills/skills/cypress-e2e/references/e2e_mindset.md) for detailed examples.
