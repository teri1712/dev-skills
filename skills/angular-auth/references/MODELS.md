# Authentication Models

Standard interfaces for a robust Angular auth system.

```typescript
export interface AccessToken {
  accessToken: string;
  refreshToken: string;
}

export interface Profile {
  id: string;
  username: string;
  name: string;
  role: 'ADMIN' | 'USER';
}

export interface LoginResponse {
  profile: Profile;
  accessToken: AccessToken;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface ProblemDetail {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
}
```
