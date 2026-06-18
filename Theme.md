# Keycloak Custom Theme Guide — Solar Prism Studio

> **Prerequisites:** Keycloak installed via Docker Compose with external certs, behind Nginx.  
> **Working directory:** `/var/www/docker/keycloak/auth.shinyhomes.net`

---

## How Keycloak Theming Works

Keycloak renders login pages using **FreeMarker (`.ftl`) templates**. You create a custom theme folder, override the templates you want, mount it into the container, and select it in the admin console.

The key files:

| File | Controls |
|---|---|
| `theme.properties` | Declares parent theme, CSS imports |
| `template.ftl` | Page shell (nav, footer, head tags) — wraps every page |
| `login.ftl` | Sign-in form |
| `login-reset-password.ftl` | Forgot password / reset form |
| `register.ftl` | Registration / account activation form |
| `login-update-profile.ftl` | Profile completion after first login |
| `resources/css/login.css` | Custom stylesheet |

FreeMarker variables like `${url.loginAction}`, `${login.username!''}`, and `${msg("doLogIn")}` handle form actions, pre-filled values, and localized strings. Your theme inherits from the default `keycloak` theme so you only override what you change.

---

## Step 1 — Create the Theme Directory

```bash
cd /var/www/docker/keycloak/auth.shinyhomes.net

mkdir -p themes/solar-prism/login/resources/css
mkdir -p themes/solar-prism/login/resources/js
mkdir -p themes/solar-prism/login/resources/img
```

---

## Step 2 — Extract Default Templates for Reference

These give you the original FreeMarker variables and structure to work from.

```bash
mkdir -p default-templates
chmod 777 default-templates

docker run --rm \
  -v $(pwd)/default-templates:/tmp/out \
  --entrypoint /bin/bash \
  quay.io/keycloak/keycloak:latest \
  -c "cp -r /opt/keycloak/lib/lib/main/org.keycloak.keycloak-themes-*.jar /tmp/out/"

cd default-templates
unzip -o *.jar "theme/base/login/*" -d extracted
unzip -o *.jar "theme/keycloak/login/*" -d extracted
cd ..
```

Reference templates are now at:
- `default-templates/extracted/theme/base/login/` — base templates with all variables
- `default-templates/extracted/theme/keycloak/login/` — default styled templates

**Do not edit these directly.** Copy what you need into your theme folder.

---

## Step 3 — Create `theme.properties`

```bash
cat > themes/solar-prism/login/theme.properties << 'EOF'
parent=keycloak
import=common/keycloak

styles=css/login.css

kcHtmlClass=
kcBodyClass=
kcLogoLink=https://auth.shinyhomes.net
EOF
```

---

## Step 4 — Create `template.ftl` (Page Shell)

This wraps every login page. It defines the nav bar, footer, error messages, and HTML head.

```bash
cat > themes/solar-prism/login/template.ftl << 'ENDOFTEMPLATE'
<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${msg("loginTitle",(realm.displayName!'Solar Prism'))}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=Manrope:wght@200;300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">
    <link href="${url.resourcesPath}/css/login.css" rel="stylesheet">
    <script>
    tailwind.config = {
        theme: {
            extend: {
                colors: {
                    'midnight-navy': '#050A30',
                    'solar-yellow': '#FEA81F',
                    'surface': '#fbf8ff',
                    'surface-high': '#e6e6ff',
                    'surface-low': '#f4f2ff',
                    'on-surface': '#13183d',
                    'outline': '#77767f',
                    'outline-variant': '#c7c5cf',
                    'primary-container': '#13183d',
                    'secondary': '#4854bb',
                },
                fontFamily: {
                    headline: ['Space Grotesk', 'sans-serif'],
                    body: ['Manrope', 'sans-serif'],
                }
            }
        }
    }
    </script>
</head>
<body class="bg-surface font-body text-on-surface min-h-screen flex flex-col">

    <!-- Top Navigation -->
    <nav class="bg-midnight-navy fixed top-0 left-0 right-0 z-50 shadow-lg">
        <div class="flex justify-between items-center w-full px-8 py-4 max-w-[1440px] mx-auto">
            <div class="text-xl font-bold tracking-widest text-white uppercase font-headline">
                ${realm.displayName!'Solar Prism Studio'}
            </div>
            <div class="hidden md:flex gap-8 items-center">
                <a href="#" class="text-xs font-bold tracking-widest uppercase text-white/70 hover:text-white font-body">Security</a>
                <a href="#" class="text-xs font-bold tracking-widest uppercase text-white/70 hover:text-white font-body">Support</a>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="flex-grow flex items-center justify-center pt-24 pb-12 px-6">
        <div class="w-full max-w-md">

            <#-- Flash messages (errors, info) -->
            <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
                <div class="mb-6 p-4 rounded-xl text-sm font-medium
                    <#if message.type = 'error'>bg-red-50 text-red-700 border border-red-200</#if>
                    <#if message.type = 'success'>bg-green-50 text-green-700 border border-green-200</#if>
                    <#if message.type = 'info'>bg-blue-50 text-blue-700 border border-blue-200</#if>
                    <#if message.type = 'warning'>bg-yellow-50 text-yellow-700 border border-yellow-200</#if>
                ">
                    ${kcSanitize(message.summary)?no_esc}
                </div>
            </#if>

            <#-- Page-specific content injected here -->
            <#nested "form">

            <#if displayInfo>
                <#nested "info">
            </#if>

        </div>
    </main>

    <!-- Footer -->
    <footer class="border-t border-outline-variant/15">
        <div class="flex flex-col md:flex-row justify-between items-center px-8 py-6 max-w-[1440px] mx-auto gap-4">
            <div class="text-xs font-bold tracking-widest uppercase text-outline">
                &copy; 2024 Solar Prism Studio
            </div>
            <div class="flex gap-6">
                <a href="#" class="text-xs font-bold tracking-widest uppercase text-outline hover:text-solar-yellow">Privacy</a>
                <a href="#" class="text-xs font-bold tracking-widest uppercase text-outline hover:text-solar-yellow">Security</a>
            </div>
        </div>
    </footer>

</body>
</html>
</#macro>
ENDOFTEMPLATE
```

---

## Step 5 — Create `login.ftl` (Sign-In Page)

```bash
cat > themes/solar-prism/login/login.ftl << 'ENDOFLOGIN'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed; section>

    <#if section = "form">
        <!-- Branding -->
        <div class="text-center mb-10">
            <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary-container text-solar-yellow mb-6 shadow-xl">
                <span class="material-symbols-outlined text-4xl" style="font-variation-settings: 'FILL' 1;">shield_person</span>
            </div>
            <h1 class="text-3xl font-bold tracking-tight text-on-surface font-headline">Admin Console</h1>
            <p class="text-outline text-sm tracking-wide uppercase mt-2">Internal Architectural Management System</p>
        </div>

        <!-- Login Card -->
        <div class="bg-white rounded-3xl p-8 md:p-10 shadow-[0_48px_96px_-12px_rgba(5,10,48,0.12)]">

            <div class="flex items-center justify-center gap-2 mb-8 py-2 px-4 bg-surface-low rounded-full w-fit mx-auto">
                <span class="material-symbols-outlined text-secondary text-sm">verified_user</span>
                <span class="text-[0.65rem] font-bold tracking-widest uppercase text-on-surface/60">Secure Connection</span>
            </div>

            <form action="${url.loginAction}" method="post" class="space-y-6">

                <!-- Username -->
                <div class="space-y-2">
                    <label class="block text-[0.7rem] font-extrabold tracking-widest uppercase text-on-surface/60 ml-1" for="username">
                        ${msg("usernameOrEmail")}
                    </label>
                    <div class="relative group">
                        <span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline text-xl group-focus-within:text-secondary">person</span>
                        <input id="username" name="username" type="text"
                               value="${(login.username!'')}"
                               class="w-full pl-12 pr-4 py-4 bg-surface-high border-none rounded-xl focus:ring-2 focus:ring-secondary/20 font-body text-on-surface placeholder:text-outline/50"
                               placeholder="SH-XXXX-XXXX"
                               autofocus autocomplete="username" />
                    </div>
                    <#if messagesPerField.existsError('username')>
                        <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                    </#if>
                </div>

                <!-- Password -->
                <div class="space-y-2">
                    <div class="flex justify-between items-center ml-1">
                        <label class="text-[0.7rem] font-extrabold tracking-widest uppercase text-on-surface/60" for="password">
                            ${msg("password")}
                        </label>
                        <#if realm.resetPasswordAllowed>
                            <a href="${url.loginResetCredentialsUrl}" class="text-[0.7rem] font-bold text-secondary hover:underline underline-offset-4">
                                ${msg("doForgotPassword")}
                            </a>
                        </#if>
                    </div>
                    <div class="relative group">
                        <span class="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-outline text-xl group-focus-within:text-secondary">lock</span>
                        <input id="password" name="password" type="password"
                               class="w-full pl-12 pr-4 py-4 bg-surface-high border-none rounded-xl focus:ring-2 focus:ring-secondary/20 font-body text-on-surface placeholder:text-outline/50"
                               placeholder="••••••••••••"
                               autocomplete="current-password" />
                    </div>
                    <#if messagesPerField.existsError('password')>
                        <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</span>
                    </#if>
                </div>

                <!-- Remember Me -->
                <#if realm.rememberMe && !usernameHidden??>
                    <div class="flex items-center">
                        <input id="rememberMe" name="rememberMe" type="checkbox"
                               class="w-4 h-4 rounded border-outline-variant text-secondary focus:ring-secondary"
                               <#if login.rememberMe??>checked</#if> />
                        <label for="rememberMe" class="ml-2 text-xs text-on-surface/60 font-medium">
                            Remember this workstation for 12 hours
                        </label>
                    </div>
                </#if>

                <!-- Submit -->
                <button type="submit" name="login" class="w-full bg-solar-yellow text-[#2a1700] py-4 rounded-xl font-bold tracking-widest uppercase text-sm shadow-[0_8px_24px_rgba(254,168,31,0.3)] hover:translate-y-[-2px] hover:shadow-[0_12px_32px_rgba(254,168,31,0.4)] active:scale-95 transition-all duration-150">
                    ${msg("doLogIn")}
                </button>
            </form>

            <#if realm.password && realm.registrationAllowed>
                <p class="mt-8 text-center text-sm text-outline">
                    ${msg("noAccount")}
                    <a href="${url.registrationUrl}" class="font-bold text-primary-container underline decoration-solar-yellow underline-offset-4">
                        ${msg("doRegister")}
                    </a>
                </p>
            </#if>

            <p class="mt-6 text-center text-[0.65rem] text-outline leading-relaxed px-4">
                Unauthorized access is strictly prohibited and monitored under Global Security Protocol 4-A.
            </p>
        </div>
    </#if>

</@layout.registrationLayout>
ENDOFLOGIN
```

---

## Step 6 — Create `login-reset-password.ftl` (Forgot Password)

```bash
cat > themes/solar-prism/login/login-reset-password.ftl << 'ENDOFRESET'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true displayMessage=!messagesPerField.existsError('username'); section>

    <#if section = "form">
        <div class="bg-white rounded-3xl shadow-[0_48px_96px_-12px_rgba(5,10,48,0.12)] overflow-hidden">

            <!-- Header image area -->
            <div class="h-32 w-full bg-midnight-navy"></div>

            <div class="px-8 pb-12 pt-10">
                <div class="mb-8">
                    <h1 class="font-headline text-3xl font-bold text-primary-container tracking-tight mb-4">
                        Reset Your Portal Key
                    </h1>
                    <p class="text-outline text-base leading-relaxed">
                        Enter your registered email address to receive access recovery instructions.
                    </p>
                </div>

                <form action="${url.loginAction}" method="post" class="space-y-8">
                    <div class="space-y-2">
                        <label for="username" class="block text-[10px] uppercase tracking-widest font-bold text-on-surface/60 ml-1">
                            ${msg("usernameOrEmail")}
                        </label>
                        <div class="relative">
                            <input id="username" name="username" type="text"
                                   value="${(auth.attemptedUsername!'')}"
                                   class="w-full px-5 py-4 bg-surface-high border-none rounded-xl text-on-surface placeholder:text-on-surface/40 focus:ring-2 focus:ring-outline font-body"
                                   placeholder="name@architecture.com"
                                   autofocus autocomplete="username" />
                            <div class="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface/30">
                                <span class="material-symbols-outlined text-lg">alternate_email</span>
                            </div>
                        </div>
                        <#if messagesPerField.existsError('username')>
                            <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                        </#if>
                    </div>

                    <button type="submit" class="w-full py-4 px-6 bg-solar-yellow text-[#2a1700] font-headline font-bold rounded-full hover:opacity-90 transition-all shadow-md hover:translate-y-[-2px] flex justify-center items-center gap-3">
                        <span>${msg("doSubmit")}</span>
                        <span class="material-symbols-outlined text-lg">arrow_forward</span>
                    </button>
                </form>

                <div class="mt-10 pt-8 border-t border-outline-variant/10 text-center">
                    <a href="${url.loginUrl}" class="inline-flex items-center gap-2 text-sm font-bold text-on-surface/60 hover:text-primary-container group">
                        <span class="material-symbols-outlined text-lg group-hover:-translate-x-1 transition-transform">arrow_back</span>
                        ${msg("backToLogin")}
                    </a>
                </div>
            </div>
        </div>
    </#if>

    <#if section = "info">
    </#if>

</@layout.registrationLayout>
ENDOFRESET
```

---

## Step 7 — Create `register.ftl` (Account Activation)

```bash
cat > themes/solar-prism/login/register.ftl << 'ENDOFREG'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>

    <#if section = "form">
        <div class="bg-white rounded-3xl p-8 md:p-10 shadow-[0_48px_96px_-12px_rgba(5,10,48,0.12)]">

            <div class="mb-8">
                <span class="inline-block px-3 py-1 bg-surface-high text-on-surface/70 text-[10px] uppercase tracking-widest font-bold rounded-full mb-4">Resident Portal</span>
                <h2 class="font-headline text-3xl font-bold text-on-surface tracking-tight">Account Activation</h2>
                <p class="text-outline mt-2">Enter your details to establish secure access.</p>
            </div>

            <form action="${url.registrationAction}" method="post" class="space-y-5">

                <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-2">
                        <label for="firstName" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("firstName")}</label>
                        <input id="firstName" name="firstName" type="text"
                               value="${(register.formData.firstName!'')}"
                               class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                               placeholder="First name" />
                    </div>
                    <div class="space-y-2">
                        <label for="lastName" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("lastName")}</label>
                        <input id="lastName" name="lastName" type="text"
                               value="${(register.formData.lastName!'')}"
                               class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                               placeholder="Last name" />
                    </div>
                </div>

                <div class="space-y-2">
                    <label for="email" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("email")}</label>
                    <input id="email" name="email" type="email"
                           value="${(register.formData.email!'')}"
                           class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                           placeholder="name@domain.com" />
                    <#if messagesPerField.existsError('email')>
                        <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('email'))?no_esc}</span>
                    </#if>
                </div>

                <#if !realm.registrationEmailAsUsername>
                    <div class="space-y-2">
                        <label for="username" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("username")}</label>
                        <input id="username" name="username" type="text"
                               value="${(register.formData.username!'')}"
                               class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                               placeholder="Username" />
                        <#if messagesPerField.existsError('username')>
                            <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                        </#if>
                    </div>
                </#if>

                <div class="space-y-2">
                    <label for="password" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("password")}</label>
                    <input id="password" name="password" type="password"
                           class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                           placeholder="••••••••" />
                    <#if messagesPerField.existsError('password')>
                        <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</span>
                    </#if>
                </div>

                <div class="space-y-2">
                    <label for="password-confirm" class="block text-xs font-bold text-on-surface/60 uppercase tracking-wider ml-1">${msg("passwordConfirm")}</label>
                    <input id="password-confirm" name="password-confirm" type="password"
                           class="w-full bg-surface-low border-transparent rounded-xl p-4 text-on-surface placeholder:text-outline focus:ring-2 focus:ring-midnight-navy font-body"
                           placeholder="••••••••" />
                    <#if messagesPerField.existsError('password-confirm')>
                        <span class="text-red-500 text-xs ml-1">${kcSanitize(messagesPerField.getFirstError('password-confirm'))?no_esc}</span>
                    </#if>
                </div>

                <div class="pt-4">
                    <button type="submit" class="w-full bg-solar-yellow text-[#2a1700] font-headline font-bold py-5 px-8 rounded-2xl shadow-xl shadow-solar-yellow/20 hover:shadow-solar-yellow/40 hover:-translate-y-1 transition-all active:scale-[0.98]">
                        Activate My Portal
                    </button>
                </div>

                <p class="text-center text-xs text-outline mt-6">
                    Already activated?
                    <a href="${url.loginUrl}" class="font-bold text-primary-container underline decoration-solar-yellow underline-offset-4">Sign in here</a>
                </p>
            </form>
        </div>
    </#if>

</@layout.registrationLayout>
ENDOFREG
```

---

## Step 8 — Create CSS Override File

```bash
cat > themes/solar-prism/login/resources/css/login.css << 'EOF'
/* Hide any leftover default Keycloak chrome */
#kc-header-wrapper,
.kc-logo-text {
    display: none;
}
#kc-content {
    padding: 0;
}
#kc-form {
    max-width: 100%;
}
EOF
```

---

## Step 9 — Mount the Theme in Docker Compose

Edit your compose file:

```bash
vim docker-compose.external-cert.yml
```

Add this volume under the `keycloak` service's `volumes:` section:

```yaml
volumes:
  - ./themes/solar-prism:/opt/keycloak/themes/solar-prism
```

---

## Step 10 — Restart Keycloak

```bash
docker compose -f docker-compose.external-cert.yml down
docker compose -f docker-compose.external-cert.yml up -d
```

---

## Step 11 — Activate the Theme

1. Go to `https://auth.shinyhomes.net/admin`
2. Navigate to **Realm Settings** → **Themes** tab
3. Set **Login Theme** to `solar-prism`
4. Click **Save**

---

## Step 12 — Test

Open a private/incognito window and visit:

```
https://auth.shinyhomes.net/realms/YOUR-REALM/account
```

You should see your custom login page.

---

## Final Directory Structure

```
/var/www/docker/keycloak/auth.shinyhomes.net/
├── docker-compose.external-cert.yml
├── .env
├── default-templates/          ← reference only, not mounted
│   └── extracted/
│       └── theme/
│           ├── base/login/     ← all FreeMarker variables
│           └── keycloak/login/ ← default styled templates
└── themes/
    └── solar-prism/
        └── login/
            ├── theme.properties
            ├── template.ftl
            ├── login.ftl
            ├── login-reset-password.ftl
            ├── register.ftl
            └── resources/
                └── css/
                    └── login.css
```

---

## Key FreeMarker Variables Reference

| Variable | What It Does |
|---|---|
| `${url.loginAction}` | Form POST target for login |
| `${url.registrationAction}` | Form POST target for registration |
| `${url.loginResetCredentialsUrl}` | Link to forgot password page |
| `${url.registrationUrl}` | Link to registration page |
| `${url.loginUrl}` | Link back to login page |
| `${url.resourcesPath}` | Path to your theme's `resources/` folder |
| `${login.username!''}` | Pre-filled username (empty string fallback) |
| `${msg("doLogIn")}` | Localized "Sign In" button text |
| `${msg("doRegister")}` | Localized "Register" text |
| `${msg("doSubmit")}` | Localized "Submit" text |
| `${msg("usernameOrEmail")}` | Localized label text |
| `${msg("password")}` | Localized "Password" label |
| `${msg("doForgotPassword")}` | Localized "Forgot password?" text |
| `${msg("backToLogin")}` | Localized "Back to login" text |
| `${msg("noAccount")}` | Localized "No account?" text |
| `${realm.displayName!''}` | Realm display name |
| `${realm.rememberMe}` | Whether "remember me" is enabled |
| `${realm.resetPasswordAllowed}` | Whether password reset is enabled |
| `${realm.registrationAllowed}` | Whether self-registration is enabled |
| `${realm.registrationEmailAsUsername}` | Whether email is used as username |
| `${messagesPerField.existsError('field')}` | Check if a field has validation errors |
| `${messagesPerField.getFirstError('field')}` | Get first error message for a field |
| `${kcSanitize(text)?no_esc}` | Sanitize and render HTML in messages |
| `${message.summary}` | Flash message text |
| `${message.type}` | Flash message type: error, success, info, warning |

---

## How to Rollback

**Switch theme only (keep files):**

Admin Console → **Realm Settings** → **Themes** → set Login Theme back to **keycloak** → Save.

**Full removal:**

```bash
cd /var/www/docker/keycloak/auth.shinyhomes.net

rm -rf themes/solar-prism
rm -rf default-templates

# Remove the volume mount line from compose:
vim docker-compose.external-cert.yml
# delete: - ./themes/solar-prism:/opt/keycloak/themes/solar-prism

docker compose -f docker-compose.external-cert.yml down
docker compose -f docker-compose.external-cert.yml up -d
```

---

## Tips

- **Template changes are instant** — refresh the page to see updates (unless theme caching is enabled, in which case restart the container).
- **Check logs** if something breaks: `docker compose -f docker-compose.external-cert.yml logs keycloak`
- **Disable caching during development** by adding this env var to your compose file: `KC_SPI_THEME_CACHE_THEMES=false`
- **To customize more pages**, copy the corresponding `.ftl` from `default-templates/extracted/theme/base/login/` into your theme folder, then restyle it. Common ones: `login-otp.ftl` (2FA), `login-verify-email.ftl`, `error.ftl`, `info.ftl`.
- **To add social login buttons**, check `login.ftl` in the base theme for the `socialProviders` variable block and add it to your template.