---
name: write-spring-controller-test
description: Generates or updates Spring Boot controller integration tests conforming to Nexa architectural guidelines (seeding via adapters/events, @ComponentTest datasets, @MockitoSpyBean, @WithJwtUser, BDD names, AssertJ).
---

# Write Spring Controller Test

This skill provides instructions and examples for writing integration/component tests for endpoints in the Nexa project.

## Reference Examples

When writing or editing tests, you must refer to these existing tests for code examples and patterns:
- [FaqControllerTest.java](file:///home/decade/Documents/side-projects/documents/nexa/src/test/java/com/decade/nexa/faq/integration/FaqControllerTest.java) — Example of seeding via events with `ApplicationEventPublisher`.
- [FileControllerTest.java](file:///home/decade/Documents/side-projects/documents/nexa/src/test/java/com/decade/nexa/files/integration/FileControllerTest.java) — Example of endpoint testing with MockMvc, `@WithJwtUser`, and S3 mock integration.

---

## Key Testing Rules

### 1. Test Setup & Datasets
- Every integration test class **must** use the `@ComponentTest` annotation: [ComponentTest.java](file:///home/decade/Documents/side-projects/documents/nexa/src/test/java/com/decade/nexa/common/ComponentTest.java).
- Pass appropriate dataset classes to the `datasets` parameter of `@ComponentTest` (e.g., `datasets = {FaqDataset.class, OpenAiDataset.class}`).
- If a dataset for the module under test does not exist, you must create a new implementation of `TestDataset` in the target directory (e.g., `src/test/java/com/decade/nexa/common/TestDataset.java`).
  - Example: `TestDataset` implementation:
    ```java
    @TestComponent
    @RequiredArgsConstructor
    public class ExampleDataset implements TestDataset {
        private final ExampleRepository repository;
        @Override public void setup() { /* Seed initial data if any */ }
        @Override public void clean() { repository.deleteAll(); }
    }
    ```

### 2. Seeding Strategy (Strict Entry Points)
- **Do not** seed data by calling `repository.save(...)` or writing raw SQL inside your test method. This write operation is protected.
- Data writes or seeding operations must always go through **adapters** (controllers) or **event listeners**.
  - **Adapters / Controllers**: Use `MockMvc` to perform requests that create/write data.
  - **Event Listeners**: 
    - If the listener is a transactional event listener (e.g. `@TransactionalEventListener`), use Spring Modulith test `Scenario`.
    - Otherwise, publish the event in the test method using `ApplicationEventPublisher`.
- You are free to use repository or middle-layer read operations in your assertion/verification block to check the final database state.

### 3. Dependencies on Other Modules
- For mock/spy dependencies on other modules, use `@MockitoSpyBean` to override and verify behavior.
  - Example:
    ```java
    @MockitoSpyBean
    FileApi fileApi;
    ```

### 4. Authentication
- For endpoints requiring authentication, annotate the test method or test class with the custom JWT user security context annotation:
  - `@WithJwtUser`: [WithJwtUser.java](file:///home/decade/Documents/side-projects/documents/nexa/src/test/java/com/decade/nexa/common/jwt/WithJwtUser.java).

### 5. Coding & Assertion Style
- Prefer **AssertJ** (`assertThat(...)`) for fluent, human-readable assertions.
- Use clean, self-documenting code.

### 6. BDD Test Naming
- Test names **must** follow the `givenWhenThen` BDD style.
- Format: `given[Conditions]_when[Action]_then[ExpectedResult]`
- Example: `givenItsAlr3Am_whenUserQueryFaq_thenSomeFaqMustBeReturned`

---

## Detailed Implementation Templates

### Controller Test Template (Standard HTTP / MockMvc)
```java
package com.decade.nexa.example.integration;

import com.decade.nexa.common.ComponentTest;
import com.decade.nexa.common.jwt.WithJwtUser;
import com.decade.nexa.example.adapters.out.ExampleRepository;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RequiredArgsConstructor
@ComponentTest(datasets = {ExampleDataset.class})
public class ExampleControllerTest {

    private final MockMvc mvc;
    private final ExampleRepository repository;

    @Test
    @WithJwtUser
    void givenValidPayload_whenCreateItem_thenItemIsPersistedAndReturned() throws Exception {
        // Given
        String jsonPayload = """
            {
                "name": "Sample Item"
            }
            """;

        // When & Then
        mvc.perform(post("/examples")
                .contentType("application/json")
                .content(jsonPayload))
            .andExpect(status().isCreated());

        // Verification via repository read is allowed
        var items = repository.findAll();
        assertThat(items).hasSize(1);
        assertThat(items.get(0).getName()).isEqualTo("Sample Item");
    }
}
```

### Event-Driven Seeding Template
```java
package com.decade.nexa.example.integration;

import com.decade.nexa.common.ComponentTest;
import com.decade.nexa.example.domain.events.CustomEvent;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RequiredArgsConstructor
@ComponentTest(datasets = {ExampleDataset.class})
public class ExampleEventListenerTest {

    private final MockMvc mvc;
    private final ApplicationEventPublisher publisher;

    @Test
    void givenCustomEventPublished_whenGetStatus_thenStatusIsCorrect() throws Exception {
        // Given - seed via event publisher instead of saving directly to repo
        publisher.publishEvent(new CustomEvent("data-payload"));

        // When & Then
        mvc.perform(get("/examples/status"))
            .andExpect(status().isOk());
    }
}
```
