---
name: openai-setup
description: Agnostic instructions for setting up and testing OpenAI integration in Spring Boot projects using Spring AI. Use when configuring API keys, base URLs, or setting up WireMock stubs for testing.
---

# OpenAI Setup & Testing

## Development Setup

To enable OpenAI in a Spring AI project, typically use a dedicated Spring profile (e.g., `openai`).

1. **Configuration**: Use `application-openai.yaml` or similar.
   ```yaml
   spring:
     ai:
       openai:
         api-key: ${OPENAI_API_KEY}
         base-url: ${OPENAI_BASE_URL:https://api.openai.com}
         chat:
           options:
             model: gpt-4o
   ```
2. **Environment Variable**: Set your API key.
   ```bash
   export OPENAI_API_KEY=your_actual_key
   ```
3. **Running**:
   ```bash
   mvn spring-boot:run -Dspring-boot.run.profiles=dev,openai
   ```

## Testing Setup (WireMock)

For integration tests, use WireMock to avoid hitting the real API.

### 1. WireMock Infrastructure
Configure a `WireMockServer` bean and register its dynamic port in your test configuration.

```java
@Bean(initMethod = "start", destroyMethod = "stop")
public WireMockServer openAiWireMockServer() {
    return new WireMockServer(WireMockConfiguration.wireMockConfig().dynamicPort());
}

@Bean
DynamicPropertyRegistrar openAiProperties(WireMockServer openAiWireMockServer) {
    return registry -> {
        registry.add("spring.ai.openai.base-url", () -> "http://localhost:" + openAiWireMockServer.port());
        registry.add("spring.ai.openai.api-key", () -> "test-key");
    };
}
```

### 2. Stubbing Responses
Create a utility class (e.g., `OpenAiTestData`) to manage WireMock stubs.

**Chat Completion Stub:**
```java
openAiWireMockServer.stubFor(post(urlEqualTo("/v1/chat/completions"))
    .willReturn(aResponse()
        .withHeader("Content-Type", "application/json")
        .withBody("{\"choices\": [{\"message\": {\"content\": \"Mocked Response\"}}]}")));
```

**Embeddings Stub:**
```java
openAiWireMockServer.stubFor(post(urlEqualTo("/v1/embeddings"))
    .willReturn(aResponse()
        .withHeader("Content-Type", "application/json")
        .withBody("{\"data\": [{\"embedding\": [0.1, 0.2, ...]}]}")));
```

## Best Practices
- **API Key Security**: Never hardcode keys; always use placeholders like `${OPENAI_API_KEY}`.
- **Dynamic Ports**: Use dynamic WireMock ports to avoid conflicts in CI/CD environments.
- **Streaming Support**: When stubbing chat completions, handle both streaming (`text/event-stream`) and non-streaming responses if your application uses both.
