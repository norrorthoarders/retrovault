<?php
declare(strict_types=1);

/**
 * The screens a native client had to send somebody to a browser for.
 *
 * Three of them, and the ones every account uses rather than only an
 * administrator: your own details, what you want to be told about, and - for an
 * administrator - how the instance is configured.
 *
 * User management, library management, the logs and maintenance are still web
 * only. They are listed here so the next person reading this file knows the gap
 * is deliberate and not an oversight.
 */

// ---------------------------------------------------------------------------
// Your own account
// ---------------------------------------------------------------------------

function api_profile_show(): void
{
    [$user] = api_require_auth();
    $row = one('SELECT id, username, display_name, email, email_verified_at, role,
                       avatar_filename, created_at, last_login_at
                  FROM users WHERE id = ?', [(int) $user['id']]);
    if ($row === null) {
        api_error('not_found', 'That account no longer exists.', 404);
    }

    api_ok([
        'id'           => (int) $row['id'],
        // Not editable here on purpose. A username is what other people's
        // library memberships point at by sight, and renaming one quietly is a
        // different job from editing a profile.
        'username'     => $row['username'],
        'display_name' => $row['display_name'],
        'email'        => $row['email'],
        'email_verified' => ($row['email_verified_at'] ?? null) !== null,
        'role'         => $row['role'],
        'avatar'       => absolute_url(image_url($row['avatar_filename'] ?? null, 'thumb')),
        'created_at'   => api_datetime($row['created_at'] ?? null),
        'last_login_at'=> api_datetime($row['last_login_at'] ?? null),
    ]);
}

/**
 * Change your display name, your address, or your password.
 *
 * A password change wants the current one, even though the caller is already
 * holding a valid token: a phone left unlocked on a table is exactly the case
 * where "already signed in" is not the same as "is the account holder".
 */
function api_profile_update(): void
{
    [$user] = api_require_write();
    $in     = api_body();
    $id     = (int) $user['id'];
    $fields = [];

    if (array_key_exists('display_name', $in)) {
        $name = trim((string) $in['display_name']);
        $fields['display_name'] = $name === '' ? null : mb_substr($name, 0, 120);
    }

    if (array_key_exists('email', $in)) {
        $email = trim((string) $in['email']);
        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            api_error('validation_failed', 'That does not look like an address.', 422,
                      ['email' => 'That does not look like an address.']);
        }
        if ($email !== '' && one('SELECT id FROM users WHERE email = ? AND id <> ?', [$email, $id]) !== null) {
            api_error('validation_failed', 'Another account already uses that address.', 422,
                      ['email' => 'Another account already uses that address.']);
        }
        $fields['email'] = $email === '' ? null : $email;
    }

    if (array_key_exists('password', $in)) {
        $current = (string) ($in['current_password'] ?? '');
        $fresh   = (string) $in['password'];
        $row     = one('SELECT password_hash FROM users WHERE id = ?', [$id]);

        if ($row === null || !password_verify($current, (string) $row['password_hash'])) {
            api_error('validation_failed', 'The current password is not right.', 422,
                      ['current_password' => 'The current password is not right.']);
        }
        if (mb_strlen($fresh) < 10) {
            api_error('validation_failed', 'A password needs at least ten characters.', 422,
                      ['password' => 'A password needs at least ten characters.']);
        }
        $fields['password_hash'] = password_hash($fresh, PASSWORD_DEFAULT);
    }

    if ($fields === []) {
        api_error('validation_failed', 'Nothing to change.', 422);
    }

    update_row('users', $id, $fields);
    // Logged where it happens, because a password change is a security event and
    // nothing further down would know one had occurred.
    if (isset($fields['password_hash'])) {
        log_security('password.changed', 'Password changed from the API.', LOG_NOTICE);
    }

    api_profile_show();
}

// ---------------------------------------------------------------------------
// What you want to be told about
// ---------------------------------------------------------------------------

/**
 * Described, not just the values.
 *
 * Which kinds exist is decided in notify.php and changes; a client that had them
 * written down would quietly stop offering the new ones.
 */
function api_notification_prefs_show(): void
{
    [$user] = api_require_auth();

    $out = [];
    foreach (notification_prefs_for((int) $user['id']) as $kind => $pref) {
        $out[] = [
            'kind'        => $kind,
            'label'       => $pref['label'],
            'description' => $pref['description'],
            'in_app'      => (bool) $pref['in_app'],
            'by_mail'     => (bool) $pref['by_mail'],
            // Whether this account has ever said, as opposed to inheriting the
            // default for the kind.
            'explicit'    => (bool) $pref['explicit'],
        ];
    }

    api_ok($out, [
        // Mail that is not configured cannot be sent, so a client can grey the
        // column rather than offer a switch that does nothing.
        'mail_enabled' => (bool) setting('smtp_enabled', ''),
    ]);
}

function api_notification_prefs_update(): void
{
    [$user] = api_require_write();
    $in     = api_body();
    $prefs  = $in['prefs'] ?? null;

    if (!is_array($prefs)) {
        api_error('validation_failed',
                  'Send prefs as an object of kind => {in_app, by_mail}.', 422);
    }

    $known = notification_kinds();
    foreach (array_keys($prefs) as $kind) {
        if (!isset($known[$kind])) {
            api_error('validation_failed', 'No notification kind called "' . $kind . '".', 422);
        }
    }

    // save_notification_prefs() writes every kind, treating anything missing as
    // off - which is right for a form that posts checkboxes and wrong for a
    // client sending one changed switch. So the current set is read first and
    // what arrived is laid over it.
    $merged = ['in_app' => [], 'by_mail' => []];
    foreach (notification_prefs_for((int) $user['id']) as $kind => $pref) {
        $merged['in_app'][$kind]  = $pref['in_app']  ? 1 : null;
        $merged['by_mail'][$kind] = $pref['by_mail'] ? 1 : null;
        if (isset($prefs[$kind]) && is_array($prefs[$kind])) {
            foreach (['in_app', 'by_mail'] as $channel) {
                if (array_key_exists($channel, $prefs[$kind])) {
                    $merged[$channel][$kind] = filter_var(
                        $prefs[$kind][$channel], FILTER_VALIDATE_BOOL) ? 1 : null;
                }
            }
        }
    }

    save_notification_prefs((int) $user['id'], $merged);
    api_notification_prefs_show();
}

// ---------------------------------------------------------------------------
// The instance
// ---------------------------------------------------------------------------

/**
 * The settings, and what each one is.
 *
 * The description comes with the values so a client can draw the form without
 * knowing anything about RetroVault's settings in advance - and so a setting
 * added to settings_schema() next year appears in an app nobody rebuilt.
 */
function api_settings_show(): void
{
    api_require_admin();

    $sections = [];
    foreach (settings_schema() as $key => $section) {
        $fields = [];
        foreach ($section['fields'] as $name => $field) {
            $described = [
                'name'  => $name,
                'kind'  => $field['kind'],
                'label' => $field['label'],
                'value' => setting_to_api($name, $field),
            ];
            foreach (['help', 'min', 'max'] as $extra) {
                if (isset($field[$extra])) { $described[$extra] = $field[$extra]; }
            }
            if (isset($field['options'])) {
                $described['options'] = array_map(
                    fn($value, $label) => ['value' => (string) $value, 'label' => $label],
                    array_keys($field['options']),
                    array_values($field['options'])
                );
            }
            if ($field['kind'] === 'secret') {
                // Never the value. Whether there is one is all a form needs to
                // decide between "change it" and "set it".
                $described['is_set'] = setting($name, '') !== '';
            }
            $fields[] = $described;
        }
        $sections[] = [
            'key'    => $key,
            'label'  => $section['label'],
            'help'   => $section['help'] ?? null,
            'fields' => $fields,
        ];
    }

    api_ok($sections, [
        'app_version' => APP_VERSION,
        'php_version' => PHP_VERSION,
    ]);
}

/**
 * Change some of them.
 *
 * Everything is checked before anything is written. A request that sets a good
 * host and a bad port used to be worth half applying; it is not, because the half
 * that applied is the half nobody was told about.
 */
function api_settings_update(): void
{
    api_require_admin();
    $in     = api_body();
    $wanted = $in['settings'] ?? null;

    if (!is_array($wanted) || $wanted === []) {
        api_error('validation_failed', 'Send settings as an object of name => value.', 422);
    }

    $schema  = settings_schema_fields();
    $checked = [];
    $errors  = [];

    foreach ($wanted as $name => $value) {
        if (!isset($schema[$name])) {
            $errors[(string) $name] = 'There is no setting called that.';
            continue;
        }
        [$storable, $problem] = setting_from_api((string) $name, $schema[$name], $value);
        if ($problem !== null) {
            $errors[(string) $name] = $problem;
            continue;
        }
        $checked[(string) $name] = $storable;
    }

    if ($errors !== []) {
        api_error('validation_failed', 'Some settings were refused.', 422, $errors);
    }

    foreach ($checked as $name => $value) {
        set_setting($name, $value);
    }

    api_settings_show();
}
