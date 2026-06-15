# Authentication Models & Interfaces

Standard interfaces and models for a robust Angular auth system.

## Interfaces (Abstract Classes)
We use abstract classes as interfaces to allow Injection Tokens without manual `InjectionToken` creation.

```typescript
// auth-service.interface.ts
export abstract class IAuthService {
    abstract loginWithCredentials(credentials: AdminLoginRequest): Observable<ProfileResponse>;
    abstract registerAdmin(data: SignUpRequest): Observable<ProfileResponse>;
    abstract changePassword(newPassword: string, currentPassword?: string): Observable<ProfileResponse>;
    abstract logout(): void;
}

// token-store.interface.ts
export abstract class ITokenStore {
    abstract readonly isLoggedIn: Signal<boolean>;
    abstract readonly sessionExpired: Signal<boolean>;
    abstract getAccessToken(): string | null;
}

export abstract class IProfileStore {
    abstract readonly profile: Signal<ProfileResponse | null>;
    abstract readonly isAdmin: Signal<boolean>;
}
```

## Data Models

```typescript
export interface AccessToken {
  accessToken: string;
  refreshToken: string;
}

export interface ProfileResponse {
  id: string;
  username: string;
  name: string;
  role: 'ADMIN' | 'USER' | string;
}

export interface AccountResponse {
  profile: ProfileResponse;
  accessToken: AccessToken;
}

export interface AdminLoginRequest {
  username: string;
  password: string;
}

export interface SignUpRequest {
  username: string;
  password: string;
  name: string;
  gender: number;
  dob: string;
}

export interface ProblemDetail {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
}
```
