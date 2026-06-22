---
name: write-spring-controller-test
description: Generates or updates Spring Boot controller integration tests conforming to Nexa architectural guidelines (seeding via adapters/events, @ComponentTest datasets, @MockitoSpyBean, @WithJwtUser, BDD names, AssertJ).
---

# Write Spring Controller Test

This skill provides instructions and real codebase examples for writing integration/component tests for endpoints in the Nexa project.

---

## Key Testing Rules

### 1. Test Setup & Datasets
- Every integration test class **must** use the `@ComponentTest` annotation (assume it already exists in the project).
- Pass appropriate dataset classes to the `datasets` parameter of `@ComponentTest` (e.g., `datasets = {FaqDataset.class, OpenAiDataset.class}`).
- If a dataset for the module under test does not exist, you must create a new implementation of `TestDataset` for cleaning up / setting up tests.
  - Example `TestDataset` implementation:
    ```java
    package com.decade.nexa.common;

    import org.springframework.boot.test.context.TestComponent;

    @TestComponent
    public interface TestDataset {
        default void clean() {}
        default void setup() {}
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
- For endpoints requiring authentication, annotate the test method or test class with the custom JWT user security context annotation `@WithJwtUser` (assume it already exists in the project).

### 5. Coding & Assertion Style
- Prefer **AssertJ** (`assertThat(...)`) for fluent, human-readable assertions.
- Use clean, self-documenting code.

### 6. BDD Test Naming
- Test names **must** follow the `givenWhenThen` BDD style.
- Format: `given[Conditions]_when[Action]_then[ExpectedResult]`
- Example: `givenItsAlr3Am_whenUserQueryFaq_thenSomeFaqMustBeReturned`

---

## Reference Codebase Examples

### 1. Seeding via Event Publication Example

Based on `FaqControllerTest.java` in the faq module:

```java
package com.decade.nexa.faq.integration;

import com.decade.nexa.common.ComponentTest;
import com.decade.nexa.common.OpenAiDataset;
import com.decade.nexa.documents.domain.events.UserSearched;
import com.decade.nexa.faq.adapters.ClusterScheduler;
import com.decade.nexa.faq.application.ports.out.FAQRepository;
import com.decade.nexa.faq.domain.FAQ;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.time.LocalDate;
import java.util.List;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RequiredArgsConstructor
@ComponentTest(datasets = {FaqDataset.class, OpenAiDataset.class})
public class FaqControllerTest {

    final MockMvc mvc;
    final ClusterScheduler scheduler;
    final FAQRepository faqs;
    final ApplicationEventPublisher publisher;

    @Test
    @WithMockUser(username = "teri", roles = "ADMIN")
    void givenItsAlr3Am_whenUserQueryFaq_thenSomeFaqMustBeReturned() throws Exception {
        // Given
        List<String> queries = List.of(
            // FAQ 1: Password Reset
            "How do I reset my password?",
            "I forgot my password",
            "Can't log in because I don't remember my password",
            "Where can I change my account password?",
            "Password recovery process",

            // FAQ 2: Subscription & Billing
            "How do I cancel my subscription?",
            "Stop my monthly plan",
            "How can I update my payment method?",
            "When will I be charged?",
            "Billing history not showing",

            // FAQ 3: Order Tracking
            "Where is my order?",
            "Track my shipment",
            "How do I check delivery status?",
            "My package hasn't arrived",
            "When will my order be delivered?"
        );
        for (int i = 0; i < queries.size(); i++) {
            // Seed via event listeners (Adapter/Listener entry point)
            publisher.publishEvent(new UserSearched(queries.get(i)));
        }

        // Simulate the execution of the Python clustering service, which directly
        // inserts clustered queries into the faq table in the database
        faqs.saveAll(List.of(
            new FAQ(1L, null, List.of("How do I reset my password?", "I forgot my password"), LocalDate.now()),
            new FAQ(2L, null, List.of("How do I cancel my subscription?", "Stop my monthly plan"), LocalDate.now()),
            new FAQ(3L, null, List.of("Where is my order?", "Track my shipment"), LocalDate.now())
        ));

        // Trigger the scheduler to detect completed clusters and perform LLM synthesis
        scheduler.onDeadline();

        // When & Then
        mvc.perform(MockMvcRequestBuilders.get("/faqs"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.size()").value(3));
    }
}
```

### 2. Endpoint Seeding & JWT Authentication Example

Based on `FileControllerTest.java` in the files module:

```java
package com.decade.nexa.files.integration;

import com.decade.nexa.common.jwt.WithJwtUser;
import com.decade.nexa.files.dto.PresignedDownloadResponse;
import com.decade.nexa.files.dto.PresignedUploadResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.test.web.servlet.MockMvc;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RequiredArgsConstructor
public class FileControllerTest extends FileModuleTest {

    private final MockMvc mvc;
    private final ObjectMapper objectMapper;
    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucket;

    @Test
    @WithJwtUser
    void givenServerReturnPresignUpload_mustBeAbleToUploadFileWithThatUrl() throws Exception {
        String filename = "test-upload.txt";
        String content = "Hello presigned upload!";

        // 1. Get presigned upload URL via endpoint (Adapter entry point)
        String responseStr = mvc.perform(post("/files/upload")
                        .param("filename", filename))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        PresignedUploadResponse uploadResponse = objectMapper.readValue(responseStr, PresignedUploadResponse.class);
        String uploadUrl = uploadResponse.getPresignedUploadUrl();
        String fileKey = uploadResponse.getFileKey();

        assertThat(uploadUrl).isNotEmpty();
        assertThat(fileKey).isNotEmpty();

        // 2. Perform HTTP PUT to uploadUrl using java.net.http.HttpClient
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest uploadRequest = HttpRequest.newBuilder()
                .uri(URI.create(uploadUrl))
                .header("Content-Type", "application/octet-stream")
                .PUT(HttpRequest.BodyPublishers.ofString(content))
                .build();

        HttpResponse<String> uploadResult = client.send(uploadRequest, HttpResponse.BodyHandlers.ofString());
        assertThat(uploadResult.statusCode()).isEqualTo(200);

        // 3. Verify the file exists in S3 via s3Client (Read verification is permitted)
        try (ResponseInputStream<GetObjectResponse> s3Object = s3Client.getObject(GetObjectRequest.builder()
                .bucket(bucket)
                .key(fileKey)
                .build())) {
            String s3Content = new String(s3Object.readAllBytes(), StandardCharsets.UTF_8);
            assertThat(s3Content).isEqualTo(content);
        }
    }

    @Test
    @WithJwtUser
    void givenFileAlrUploadedAndWeHaveFileKey_whenUserGetDownloadUrl_thenMustReturnUrl() throws Exception {
        String fileKey = "alice_test-download.txt";
        String content = "Hello presigned download!";

        // Upload the file first to S3
        s3Client.putObject(PutObjectRequest.builder()
                .bucket(bucket)
                .key(fileKey)
                .contentType("application/octet-stream")
                .build(), software.amazon.awssdk.core.sync.RequestBody.fromString(content));

        // Get download URL
        String responseStr = mvc.perform(post("/files/download")
                        .param("filekey", fileKey))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        PresignedDownloadResponse downloadResponse = objectMapper.readValue(responseStr, PresignedDownloadResponse.class);
        assertThat(downloadResponse.getPresignedDownloadUrl()).isNotEmpty();
        assertThat(downloadResponse.getFileKey()).isEqualTo(fileKey);
    }
}
```
