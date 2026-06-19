# Keycloak Custom Theme Guide

> **Prerequisites:** Keycloak installed via Docker Compose with external certs, behind Nginx.  
> **Working directory:** `/var/www/docker/keycloak/your-domain.com`

---

## How Keycloak Theming Works

Keycloak renders login pages using **FreeMarker (`.ftl`) templates**. You create a custom theme folder, override the templates you want, mount it into the container, and select it in the admin console. Your theme inherits from the default `keycloak` theme so you only override what you change.

**Key files:**

| File | Controls |
|---|---|
| `theme.properties` | Declares parent theme, CSS imports |
| `template.ftl` | Page shell (nav, footer, head tags) — wraps every page |
| `login.ftl` | Sign-in form |
| `login-reset-password.ftl` | Forgot password / reset form |
| `register.ftl` | Registration form |
| `login-update-profile.ftl` | Profile completion after first login |
| `resources/css/login.css` | Custom stylesheet |

---

## Step 1 — Create the Theme Directory

Replace `my-theme` with whatever you want to name your theme.

```bash
cd /var/www/docker/keycloak/your-domain.com

mkdir -p themes/my-theme/login/resources/css
mkdir -p themes/my-theme/login/resources/js
mkdir -p themes/my-theme/login/resources/img
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
cat > themes/my-theme/login/theme.properties << 'EOF'
parent=keycloak
import=common/keycloak

styles=css/login.css

kcHtmlClass=
kcBodyClass=
EOF
```

---

## Step 4 — Create `template.ftl` (Page Shell)

This wraps every login page. It defines the outer HTML structure — head tags, nav, footer, and where flash messages and page content get injected.

```bash
cat > themes/my-theme/login/template.ftl << 'ENDOFTEMPLATE'
<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${msg("loginTitle",(realm.displayName!''))}</title>

    <!-- Replace with your own fonts/framework -->
    <link href="${url.resourcesPath}/css/login.css" rel="stylesheet">
</head>
<body>

    <!-- ===== YOUR NAV BAR HERE ===== -->
    <nav>
        <a href="/">${realm.displayName!''}</a>
    </nav>

    <!-- Main Content -->
    <main>
        <div>

            <#-- Flash messages (errors, success, info) -->
            <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
                <div class="alert alert-${message.type}">
                    ${kcSanitize(message.summary)?no_esc}
                </div>
            </#if>

            <#-- Page-specific content gets injected here -->
            <#nested "form">

            <#if displayInfo>
                <#nested "info">
            </#if>

        </div>
    </main>

    <!-- ===== YOUR FOOTER HERE ===== -->
    <footer>
        <p>&copy; 2024 ${realm.displayName!''}</p>
    </footer>

</body>
</html>
</#macro>
ENDOFTEMPLATE
```

---

## Step 5 — Create `login.ftl` (Sign-In Page)

```bash
cat > themes/my-theme/login/login.ftl << 'ENDOFLOGIN'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed; section>

    <#if section = "form">

        <h1>${msg("loginAccountTitle")}</h1>

        <form action="${url.loginAction}" method="post">

            <!-- Username / Email -->
            <div>
                <label for="username">${msg("usernameOrEmail")}</label>
                <input id="username" name="username" type="text"
                       value="${(login.username!'')}"
                       autofocus autocomplete="username" />
                <#if messagesPerField.existsError('username')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                </#if>
            </div>

            <!-- Password -->
            <div>
                <label for="password">${msg("password")}</label>
                <#if realm.resetPasswordAllowed>
                    <a href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a>
                </#if>
                <input id="password" name="password" type="password"
                       autocomplete="current-password" />
                <#if messagesPerField.existsError('password')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</span>
                </#if>
            </div>

            <!-- Remember Me -->
            <#if realm.rememberMe && !usernameHidden??>
                <div>
                    <input id="rememberMe" name="rememberMe" type="checkbox"
                           <#if login.rememberMe??>checked</#if> />
                    <label for="rememberMe">${msg("rememberMe")}</label>
                </div>
            </#if>

            <!-- Submit -->
            <button type="submit" name="login">${msg("doLogIn")}</button>

        </form>

        <!-- Registration link -->
        <#if realm.password && realm.registrationAllowed>
            <p>
                ${msg("noAccount")}
                <a href="${url.registrationUrl}">${msg("doRegister")}</a>
            </p>
        </#if>

    </#if>

</@layout.registrationLayout>
ENDOFLOGIN
```

---

## Step 6 — Create `login-reset-password.ftl` (Forgot Password)

```bash
cat > themes/my-theme/login/login-reset-password.ftl << 'ENDOFRESET'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true displayMessage=!messagesPerField.existsError('username'); section>

    <#if section = "form">

        <h1>${msg("emailForgotTitle")}</h1>
        <p>${msg("emailInstruction")}</p>

        <form action="${url.loginAction}" method="post">

            <div>
                <label for="username">${msg("usernameOrEmail")}</label>
                <input id="username" name="username" type="text"
                       value="${(auth.attemptedUsername!'')}"
                       autofocus autocomplete="username" />
                <#if messagesPerField.existsError('username')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                </#if>
            </div>

            <button type="submit">${msg("doSubmit")}</button>

        </form>

        <a href="${url.loginUrl}">${msg("backToLogin")}</a>

    </#if>

    <#if section = "info">
    </#if>

</@layout.registrationLayout>
ENDOFRESET
```

---

## Step 7 — Create `register.ftl` (Registration)

```bash
cat > themes/my-theme/login/register.ftl << 'ENDOFREG'
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>

    <#if section = "form">

        <h1>${msg("registerTitle")}</h1>

        <form action="${url.registrationAction}" method="post">

            <div>
                <label for="firstName">${msg("firstName")}</label>
                <input id="firstName" name="firstName" type="text"
                       value="${(register.formData.firstName!'')}" />
            </div>

            <div>
                <label for="lastName">${msg("lastName")}</label>
                <input id="lastName" name="lastName" type="text"
                       value="${(register.formData.lastName!'')}" />
            </div>

            <div>
                <label for="email">${msg("email")}</label>
                <input id="email" name="email" type="email"
                       value="${(register.formData.email!'')}" />
                <#if messagesPerField.existsError('email')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('email'))?no_esc}</span>
                </#if>
            </div>

            <#if !realm.registrationEmailAsUsername>
                <div>
                    <label for="username">${msg("username")}</label>
                    <input id="username" name="username" type="text"
                           value="${(register.formData.username!'')}" />
                    <#if messagesPerField.existsError('username')>
                        <span class="error">${kcSanitize(messagesPerField.getFirstError('username'))?no_esc}</span>
                    </#if>
                </div>
            </#if>

            <div>
                <label for="password">${msg("password")}</label>
                <input id="password" name="password" type="password" />
                <#if messagesPerField.existsError('password')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('password'))?no_esc}</span>
                </#if>
            </div>

            <div>
                <label for="password-confirm">${msg("passwordConfirm")}</label>
                <input id="password-confirm" name="password-confirm" type="password" />
                <#if messagesPerField.existsError('password-confirm')>
                    <span class="error">${kcSanitize(messagesPerField.getFirstError('password-confirm'))?no_esc}</span>
                </#if>
            </div>

            <button type="submit">${msg("doRegister")}</button>

            <p>
                <a href="${url.loginUrl}">${msg("backToLogin")}</a>
            </p>

        </form>

    </#if>

</@layout.registrationLayout>
ENDOFREG
```

---

## Step 8 — Create CSS File

```bash
cat > themes/my-theme/login/resources/css/login.css << 'EOF'
/* Hide leftover default Keycloak chrome */
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

/* ===== ADD YOUR STYLES BELOW ===== */
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
  - ./themes/my-theme:/opt/keycloak/themes/my-theme
```

---

## Step 10 — Restart Keycloak

```bash
docker compose -f docker-compose.external-cert.yml down
docker compose -f docker-compose.external-cert.yml up -d
```

---

## Step 11 — Activate the Theme

1. Go to `https://your-domain.com/admin`
2. Navigate to **Realm Settings** → **Themes** tab
3. Set **Login Theme** to `my-theme`
4. Click **Save**

---

## Step 12 — Test

Open a private/incognito window and visit:

```
https://your-domain.com/realms/YOUR-REALM/account
```

---

## Final Directory Structure

```
/var/www/docker/keycloak/your-domain.com/
├── docker-compose.external-cert.yml
├── .env
├── default-templates/          ← reference only, not mounted
│   └── extracted/
│       └── theme/
│           ├── base/login/     ← all FreeMarker variables
│           └── keycloak/login/ ← default styled templates
└── themes/
    └── my-theme/
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

## FreeMarker Variables Reference

### URLs

| Variable | What It Does |
|---|---|
| `${url.loginAction}` | Form POST target for login |
| `${url.registrationAction}` | Form POST target for registration |
| `${url.loginResetCredentialsUrl}` | Link to forgot password page |
| `${url.registrationUrl}` | Link to registration page |
| `${url.loginUrl}` | Link back to login page |
| `${url.resourcesPath}` | Path to your theme's `resources/` folder |

### User Input

| Variable | What It Does |
|---|---|
| `${login.username!''}` | Pre-filled username on login |
| `${(auth.attemptedUsername!'')}` | Pre-filled username on password reset |
| `${(register.formData.firstName!'')}` | Pre-filled first name on registration |
| `${(register.formData.lastName!'')}` | Pre-filled last name on registration |
| `${(register.formData.email!'')}` | Pre-filled email on registration |
| `${(register.formData.username!'')}` | Pre-filled username on registration |
| `${login.rememberMe??}` | Whether "remember me" was previously checked |

### Localized Strings

| Variable | Default English Text |
|---|---|
| `${msg("loginTitle",(realm.displayName!''))}` | Page title |
| `${msg("loginAccountTitle")}` | "Sign In" heading |
| `${msg("usernameOrEmail")}` | "Username or Email" |
| `${msg("password")}` | "Password" |
| `${msg("doLogIn")}` | "Sign In" |
| `${msg("doRegister")}` | "Register" |
| `${msg("doSubmit")}` | "Submit" |
| `${msg("doForgotPassword")}` | "Forgot Password?" |
| `${msg("backToLogin")}` | "Back to Login" |
| `${msg("noAccount")}` | "No account?" |
| `${msg("rememberMe")}` | "Remember Me" |
| `${msg("registerTitle")}` | "Register" heading |
| `${msg("emailForgotTitle")}` | "Forgot Password" heading |
| `${msg("emailInstruction")}` | Reset password instructions |
| `${msg("firstName")}` | "First Name" |
| `${msg("lastName")}` | "Last Name" |
| `${msg("email")}` | "Email" |
| `${msg("username")}` | "Username" |
| `${msg("passwordConfirm")}` | "Confirm Password" |

### Realm Settings (Booleans)

| Variable | What It Does |
|---|---|
| `${realm.displayName!''}` | Realm display name |
| `${realm.rememberMe}` | Whether "remember me" is enabled |
| `${realm.resetPasswordAllowed}` | Whether password reset is enabled |
| `${realm.registrationAllowed}` | Whether self-registration is enabled |
| `${realm.registrationEmailAsUsername}` | Whether email is used as username |

### Validation Errors

| Variable | What It Does |
|---|---|
| `${messagesPerField.existsError('fieldName')}` | Check if a field has errors |
| `${messagesPerField.getFirstError('fieldName')}` | Get first error for a field |
| `${kcSanitize(text)?no_esc}` | Sanitize and render HTML in messages |
| `${message.summary}` | Flash message text |
| `${message.type}` | Flash type: `error`, `success`, `info`, `warning` |

---

## How to Rollback

**Switch theme only (keep files):**

Admin Console → **Realm Settings** → **Themes** → set Login Theme back to **keycloak** → Save.

**Full removal:**

```bash
cd /var/www/docker/keycloak/your-domain.com

rm -rf themes/my-theme
rm -rf default-templates

# Remove the volume mount line from compose:
vim docker-compose.external-cert.yml
# delete: - ./themes/my-theme:/opt/keycloak/themes/my-theme

docker compose -f docker-compose.external-cert.yml down
docker compose -f docker-compose.external-cert.yml up -d
```

---

## Tips

- **Template changes are instant** — refresh the page to see updates (unless theme caching is enabled, then restart the container).
- **Check logs** if something breaks: `docker compose -f docker-compose.external-cert.yml logs keycloak`
- **Disable caching during development** by adding this env var to your compose file: `KC_SPI_THEME_CACHE_THEMES=false`
- **To customize more pages**, copy the `.ftl` from `default-templates/extracted/theme/base/login/` into your theme folder and restyle it. Common ones: `login-otp.ftl` (2FA), `login-verify-email.ftl`, `error.ftl`, `info.ftl`.
- **To add social login buttons**, check `login.ftl` in the base theme for the `socialProviders` variable block and add it to your template.
- **Custom localization**: create `themes/my-theme/login/messages/messages_en.properties` to override any `msg()` string.