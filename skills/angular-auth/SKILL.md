---
name: angular-auth
description: Set up a robust Angular authentication system with AuthService, TokenStore, and HttpInterceptor. Use when implementing login, token management, and authorized requests in Angular projects.
---

# Angular Authentication Pattern

This skill provides a standard, robust pattern for implementing authentication in Angular applications. It leverages a single-instance `AuthService` that manages both business logic and session state (`TokenStore`), coupled with a functional `HttpInterceptor` for automatic Bearer token attachment.

## Quick Start

1. Define your **Auth Models** (User profile, Tokens, Login requests).
2. Implement the **TokenStore** to manage `localStorage` and `signals` for reactive state.
3. Implement the **AuthService** (extending `TokenStore`) for HTTP calls (login, register, logout).
4. Register the **AuthInterceptor** in your `app.config.ts`.

## Core Components

### 1. TokenStore & AuthService
The `AuthService` should extend a `TokenStore` class to centralize session management. Use Angular **Signals** for reactive UI updates (e.g., `isLoggedIn`, `profile`).

```typescript
// token-store.service.ts
@Injectable()
export class TokenStore {
  protected readonly _profile = signal<Profile | null>(this.loadProfile());
  readonly profile = this._profile.asReadonly();
  readonly isLoggedIn = computed(() => !!this._profile());

  storeSession(profile: Profile, token: string) {
    localStorage.setItem('access_token', token);
    localStorage.setItem('profile', JSON.stringify(profile));
    this._profile.set(profile);
  }
}

// auth.service.ts
@Injectable({ providedIn: 'root' })
export class AuthService extends TokenStore {
  private readonly http = inject(HttpClient);

  login(credentials: LoginRequest) {
    return this.http.post<LoginResponse>('/api/login', credentials)
      .pipe(tap(res => this.storeSession(res.profile, res.token)));
  }
}
```

### 2. Auth Interceptor
A functional interceptor that injects `AuthService` to retrieve the token and clone the request with an `Authorization` header.

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.getAccessToken();

  const authReq = token 
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        auth.markSessionExpired();
      }
      return throwError(() => error);
    })
  );
};
```

### 3. Application Config
Provide the interceptor in `app.config.ts`:

```typescript
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([authInterceptor])),
    // ...
  ]
};
```

## Advanced Patterns
- **Auto-Refresh**: Extend the interceptor to handle 401s by attempting a refresh token call.
- **Role Guards**: Create an `AdminGuard` that checks `authService.isAdmin()`.
- **Form-Encoded Login**: Use `HttpParams` with `application/x-www-form-urlencoded` if required by the backend.

See [MODELS.md](references/MODELS.md) for standard interface definitions.
