---
name: angular-auth
description: Set up a robust Angular authentication system with AuthService, TokenStore, and HttpInterceptor. Use when implementing login, token management, and authorized requests in Angular projects.
---

# Angular Authentication Pattern

This skill provides the high-fidelity pattern used for authentication. It features a Signal-based `TokenStore` for reactive state management, a business-logic-focused `AuthService`, and a functional `HttpInterceptor`.

## Core Components

### 1. TokenStore (Session State)
Manages `localStorage` persistence and exposes reactive **Signals**.

```typescript
@Injectable()
export class TokenStore implements ITokenStore {
    private readonly _profile = signal<ProfileResponse | null>(this._loadProfile());
    private readonly _sessionExpired = signal(false);

    readonly profile = this._profile.asReadonly();
    readonly isLoggedIn = computed(() => !!this._profile());
    readonly sessionExpired = this._sessionExpired.asReadonly();
    readonly isAdmin = computed(() => this.profile()?.role === 'ADMIN');

    storeSession(profile: ProfileResponse, accessToken: string): void {
        localStorage.setItem('access_token', accessToken);
        localStorage.setItem('profile', JSON.stringify(profile));
        this._profile.set(profile);
        this._sessionExpired.set(false);
    }

    clearSession(): void {
        localStorage.removeItem('access_token');
        localStorage.removeItem('profile');
        this._profile.set(null);
        this._sessionExpired.set(false);
    }

    markSessionExpired(): void {
        this._sessionExpired.set(true);
    }

    getAccessToken(): string | null {
        return localStorage.getItem('access_token');
    }

    private _loadProfile(): ProfileResponse | null {
        const raw = localStorage.getItem('profile');
        try { return raw ? JSON.parse(raw) : null; } catch { return null; }
    }
}
```

### 2. AuthService (Business Logic)
Extends `TokenStore` to act as a single source of truth for auth operations.

```typescript
@Injectable({providedIn: 'root'})
export class AuthService extends TokenStore implements IAuthService {
    private readonly http = inject(HttpClient);
    private readonly base = environment.apiUrl;

    loginWithCredentials(credentials: AdminLoginRequest) {
        const params = new HttpParams()
            .set('username', credentials.username)
            .set('password', credentials.password);
            
        return this.http.post<AccountResponse>(`${this.base}/login`, params, {
            headers: new HttpHeaders({ 'Content-Type': 'application/x-www-form-urlencoded' })
        }).pipe(
            tap(res => this.storeSession(res.profile, res.accessToken)),
            map(res => res.profile)
        );
    }

    logout(): void {
        this.clearSession();
    }
}
```

### 3. Auth Interceptor (Functional)
Injects `AuthService` to attach Bearer tokens and handle 401 errors.

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const tokenStore = inject(AuthService);

    if (tokenStore.sessionExpired()) {
        return next(req);
    }

    const token = tokenStore.getAccessToken();
    const authReq = token
        ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
        : req;

    return next(authReq).pipe(
        catchError((error: HttpErrorResponse) => {
            const isRefresh = req.url.includes('/tokens/refresh');
            const hasProblemDetail = typeof error.error === 'object' && error.error?.detail;
            
            if (error.status === 401 && !isRefresh && !hasProblemDetail && token) {
                tokenStore.markSessionExpired();
            }
            return throwError(() => error);
        }),
    );
};
```

## Setup
Register in `app.config.ts`:
```typescript
export const appConfig: ApplicationConfig = {
    providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
    ]
};
```

See [MODELS.md](references/MODELS.md) for full interface definitions.
