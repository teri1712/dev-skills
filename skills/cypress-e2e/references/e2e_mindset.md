# Cypress E2E Mindset and Guidelines

This reference details the core principles for writing Cypress E2E tests. Follow these rules strictly when implementing new tests.

## 1. Page Reflection & Interface Validation
* E2E tests must validate that UI pages reflect data, loading, and error states correctly based on API interfaces.
* **Important**: Always stub API responses using external JSON fixture files (e.g., in `cypress/fixtures/`) rather than hardcoding stub objects inline in TypeScript/JavaScript test files.
* Use `cy.intercept` to mock API endpoints with different fixture scenarios (success, error, empty array, loading delays) and verify how the UI adapts.

### Example: Stubbing API Responses with JSON Fixtures
```typescript
// Stubbing a successful products fetch API using a JSON fixture file (cypress/fixtures/products-success.json)
cy.intercept('GET', '/api/products', {
  statusCode: 200,
  fixture: 'products-success.json'
}).as('getProducts');

// Stubbing an error response using a JSON fixture file (cypress/fixtures/error-500.json)
cy.intercept('GET', '/api/products', {
  statusCode: 500,
  fixture: 'error-500.json'
}).as('getProductsError');
```

## 2. Naming Conventions
Every test case description must follow the exact structure:
`it('should <expected result> when <action/condition occurs>', () => { ... })`

**Correct Examples:**
* `it('should display product list when server returns products success', ...)`
* `it('should show error notification when api returns 500 error', ...)`
* `it('should disable submit button when form is invalid', ...)`

**Incorrect Examples:**
* `it('tests list loading', ...)`
* `it('should fail on error', ...)`

## 3. Regression & Business Logic "Facts"
* Focus test cases on verifying fundamental business logic expectations ("facts").
* If code shifts, the tests must guard these core invariants so regressions are caught immediately.
* Do not just test "happy paths." Test behavior when data is missing, when user is unauthorized, and boundary conditions.

## 4. Collaborative/Interactive Workflow (Continuous Suggestion)
* When writing tests, always suggest potential test scenarios to the user.
* Do not write all tests in one go without feedback. Propose a list of candidate cases using the `should...when...` naming scheme, let the user pick, write them, and suggest more.
