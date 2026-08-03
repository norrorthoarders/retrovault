<?php
declare(strict_types=1);

/**
 * REST API, version 1. Every route lives under /api/v1.
 *
 * Conventions:
 *   - Success returns {"data": ...} and, for collections, {"meta": {...}}
 *   - Failure returns {"error": {"code": "...", "message": "...", "details": {}}}
 *   - Writes require write access to the library in question, and a
 *     write-scoped token. The instance role does not enter into it.
 */

// --- Meta and authentication -----------------------------------------------

function api_meta(): void
{
    api_ok([
        'name'            => config('app_name'),
        'api_version'     => API_VERSION,
        'currency'        => config('currency'),
        'timezone'        => config('timezone'),
        'server_time'     => gmdate('Y-m-d\TH:i:s\Z'),
        'authenticated'   => api_identify() !== null,
        'max_upload_bytes' => (int) config('uploads.max_bytes'),
        'image_kinds'     => array_map(
            fn($k) => ['value' => $k, 'label' => image_kind_label($k)],
            image_kind_options()
        ),
        'conditions' => array_map(
            fn($k) => ['value' => $k, 'label' => condition_label($k)],
            condition_options()
        ),
        'completeness' => array_map(
            fn($k) => ['value' => $k, 'label' => completeness_label($k)],
            completeness_options()
        ),
        'component_conditions' => array_map(
            fn($k) => ['value' => $k, 'label' => condition_label($k)],
            component_condition_options()
        ),
        'statuses' => array_map(
            fn($k) => ['value' => $k, 'label' => status_label($k)],
            status_options()
        ),
    ]);
}

/**
 * Exchange a username and password for a long-lived token.
 * This is what a native client calls on its sign-in screen.
 */
function api_login(): void
{
    $in = api_body();
    $username = trim((string) ($in['username'] ?? ''));
    $password = (string) ($in['password'] ?? '');
    $device   = trim((string) ($in['device_name'] ?? 'API client'));
    $platform = trim((string) ($in['platform'] ?? ''));
    $scope    = ($in['scope'] ?? 'write') === 'read' ? 'read' : 'write';

    if ($username === '' || $password === '') {
        api_error('validation_failed', 'Both username and password are required.', 422);
    }

    // The same limit as the web form. Without this the API would be a way
    // straight past it.
    [$allowed, $wait, $why] = throttle_check($username);
    if (!$allowed) {
        log_auth_attempt($username, null, false, 'throttled: ' . (string) $why);
        header('Retry-After: ' . $wait);
        api_error('rate_limited', throttle_message($wait), 429);
    }

    // Same resolution as the web sign-in: local password, or whichever
    // directory owns the account. Directory users have no password_hash at all,
    // so this must never call password_verify() directly.
    $row = verify_credentials($username, $password);
    if ($row === null) {
        usleep(random_int(150000, 400000)); // blunt the edge off online guessing
        api_error('invalid_credentials', 'That username and password do not match.', 401);
    }

    // An account with nothing it may change can never hold a write token,
    // whatever it asked for. That is a membership question, not a role one.
    set_acting_user($row);
    if (!can_edit_anything()) {
        $scope = 'read';
    }

    $days = (int) config('api.token_days', 0);
    $expires = $days > 0 ? date('Y-m-d H:i:s', time() + $days * 86400) : null;

    [$tokenId, $plain] = create_api_token(
        (int) $row['id'],
        $device !== '' ? $device : 'API client',
        $scope,
        $platform !== '' ? mb_substr($platform, 0, 40) : null,
        $expires
    );

    q('UPDATE users SET last_login_at = NOW() WHERE id = ?', [(int) $row['id']]);

    // Not log_auth_attempt(): verify_credentials() already writes auth_log for
    // both outcomes, and a second call there was two rows for one sign-in.
    //
    // This is the line that was genuinely missing - auth_log is its own table
    // and its own screen, while the log page shows `logs`, where the API had
    // never written anything at all. A device now holds a credential for this
    // account, named, so "which phone was that" has an answer.
    log_security('api.token.issued',
                 sprintf('Token issued to "%s" for %s, %s access',
                         $device !== '' ? $device : 'API client',
                         $username, $scope),
                 LOG_NOTICE, ['subject_type' => 'user', 'subject_id' => (int) $row['id']]);

    $user = one('SELECT id, username, display_name, role, is_active FROM users WHERE id = ?', [(int) $row['id']]);

    api_ok([
        'token'      => $plain,
        'token_id'   => $tokenId,
        'token_type' => 'Bearer',
        'scope'      => $scope,
        'expires_at' => $expires === null ? null : api_datetime($expires),
        'user'       => user_to_api($user),
    ], null, 201);
}

/** Revoke the token used to make this call. */
function api_logout(): void
{
    [, $token] = api_require_auth();
    if ($token === null) {
        api_error('not_applicable', 'This call was authenticated by a web session, not a token.', 400);
    }
    q('UPDATE api_tokens SET revoked_at = NOW() WHERE id = ?', [(int) $token['id']]);
    api_no_content();
}

function api_me(): void
{
    [$user, $token] = api_require_auth();
    api_ok([
        'user'  => user_to_api($user),
        'token' => $token === null ? null : [
            'id'           => (int) $token['id'],
            'name'         => $token['name'],
            'scope'        => $token['scope'],
            'platform'     => $token['platform'],
            'expires_at'   => api_datetime($token['expires_at']),
            'last_used_at' => api_datetime($token['last_used_at']),
        ],
    ]);
}

// --- Token management -------------------------------------------------------

function api_tokens_index(): void
{
    [$user] = api_require_auth();
    $rows = all(
        'SELECT id, name, prefix, scope, platform, last_used_at, last_used_ip, expires_at, revoked_at, created_at
         FROM api_tokens WHERE user_id = ? ORDER BY created_at DESC',
        [(int) $user['id']]
    );
    api_ok(array_map(fn($t) => [
        'id'           => (int) $t['id'],
        'name'         => $t['name'],
        'prefix'       => $t['prefix'],
        'scope'        => $t['scope'],
        'platform'     => $t['platform'],
        'last_used_at' => api_datetime($t['last_used_at']),
        'last_used_ip' => $t['last_used_ip'],
        'expires_at'   => api_datetime($t['expires_at']),
        'revoked_at'   => api_datetime($t['revoked_at']),
        'created_at'   => api_datetime($t['created_at']),
    ], $rows));
}

function api_tokens_create(): void
{
    [$user] = api_require_auth();
    $in = api_body();
    $name = trim((string) ($in['name'] ?? ''));
    if ($name === '') {
        api_error('validation_failed', 'Give the token a name so you can recognise the device later.', 422);
    }
    $scope = ($in['scope'] ?? 'write') === 'read' ? 'read' : 'write';
    if ($scope === 'write' && !can_edit_anything()) {
        $scope = 'read';
    }
    [$id, $plain] = create_api_token(
        (int) $user['id'],
        $name,
        $scope,
        isset($in['platform']) ? mb_substr((string) $in['platform'], 0, 40) : null
    );
    api_ok([
        'id'    => $id,
        'name'  => $name,
        'scope' => $scope,
        'token' => $plain,
        'note'  => 'Store this now. It is not recoverable.',
    ], null, 201);
}

function api_tokens_revoke(int $id): void
{
    [$user] = api_require_auth();
    $token = one('SELECT id, user_id FROM api_tokens WHERE id = ?', [$id]);
    if ($token === null) {
        api_error('not_found', 'No such token.', 404);
    }
    if ((int) $token['user_id'] !== (int) $user['id'] && $user['role'] !== 'admin') {
        api_error('forbidden', 'That token belongs to another account.', 403);
    }
    q('UPDATE api_tokens SET revoked_at = NOW() WHERE id = ?', [$id]);
    api_no_content();
}

// --- Items ------------------------------------------------------------------

function api_items_index(): void
{
    api_require_auth();

    $perPage = max(1, min(200, api_query_int('per_page', (int) config('per_page')) ?? 24));
    $page    = max(1, api_query_int('page', 1) ?? 1);
    $sort    = isset($_GET['sort']) && is_string($_GET['sort']) ? $_GET['sort'] : 'title';

    [$where, $params] = build_item_filters($_GET);
    $order = item_sort_clause($sort);

    $total  = (int) scalar("SELECT COUNT(*) FROM v_items WHERE $where", $params);
    $pages  = max(1, (int) ceil($total / $perPage));
    $offset = ($page - 1) * $perPage;

    $rows = all("SELECT * FROM v_items WHERE $where ORDER BY $order LIMIT $perPage OFFSET $offset", $params);

    // Cheap validator so clients can skip re-downloading an unchanged page.
    $etag = '"' . md5(implode('|', array_map(
        fn($r) => $r['id'] . ':' . $r['updated_at'],
        $rows
    )) . "|$total|$page|$perPage") . '"';

    if (($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
        http_response_code(304);
        header('ETag: ' . $etag);
        exit;
    }

    $withImages = ($_GET['include'] ?? '') === 'images';

    api_ok(
        array_map(fn($r) => item_to_api($r, $withImages), $rows),
        [
            'page'     => $page,
            'per_page' => $perPage,
            'total'    => $total,
            'pages'    => $pages,
            'has_more' => $page < $pages,
        ],
        200,
        ['ETag' => $etag, 'X-Total-Count' => (string) $total]
    );
}

function api_items_show(int $id): void
{
    api_require_auth();
    $item = find_item($id);
    if ($item === null || !can_read_item($item)) {
        api_error('not_found', 'No catalogue entry with that id.', 404);
    }
    $etag = '"' . md5($item['id'] . ':' . $item['updated_at'] . ':' . $item['image_count']) . '"';
    if (($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
        http_response_code(304);
        header('ETag: ' . $etag);
        exit;
    }
    api_ok(item_to_api($item, true), null, 200, ['ETag' => $etag]);
}

/**
 * Map an incoming JSON object onto item columns.
 * In partial mode only the supplied keys are touched, which is what PATCH needs.
 */
function api_item_input(array $in, bool $partial): array
{
    $data   = [];
    $errors = [];
    $has    = fn(string $k) => array_key_exists($k, $in);

    $strings = [
        'title' => 220, 'subtitle' => 220, 'sort_title' => 220, 'media_type' => 60,
        'catalog_number' => 80, 'barcode' => 40, 'language' => 80, 'region' => 80,
        'external_url' => 500, 'notes' => 65535,
        // The release's own blurb. Writable, because a client that can set the
        // notes and not this one would have to put a description in the notes -
        // which is the confusion migration 0014 exists to end.
        'description' => 65535,
        'lent_to' => 140,
    ];
    foreach ($strings as $key => $max) {
        if ($has($key)) {
            $v = $in[$key];
            if ($v !== null && !is_scalar($v)) {
                $errors[$key] = 'Must be a string.';
                continue;
            }
            $v = $v === null ? null : mb_substr(trim((string) $v), 0, $max);
            $data[$key] = ($v === '') ? null : $v;
        }
    }

    // The library owns the entry and decides who may see it.
    if ($has('library_id')) {
        $data['library_id'] = (int) $in['library_id'];
        if (one('SELECT id FROM libraries WHERE id = ?', [$data['library_id']]) === null) {
            $errors['library_id'] = 'No library with that id.';
        }
    }
    if ($has('platform_id')) {
        $data['platform_id'] = (int) $in['platform_id'];
        if (one('SELECT id FROM platforms WHERE id = ?', [$data['platform_id']]) === null) {
            $errors['platform_id'] = 'No platform with that id.';
        }
    }
    // Point at a canonical title, and inherit anything the caller did not
    // state. Two copies of one game should not mean sending its metadata
    // twice, and an import running twice should not produce two of it.
    if ($has('title_id')) {
        $data['title_id'] = $in['title_id'] === null ? null : (int) $in['title_id'];
        if ($data['title_id'] !== null) {
            $title = one('SELECT * FROM titles WHERE id = ?', [$data['title_id']]);
            if ($title === null) {
                $errors['title_id'] = 'No title with that id.';
            } else {
                $data += title_defaults_for_item($title, $data);
            }
        }
    }
    if ($has('category_id')) {
        $data['category_id'] = (int) $in['category_id'];
        if (one('SELECT id FROM categories WHERE id = ?', [$data['category_id']]) === null) {
            $errors['category_id'] = 'No software type with that id.';
        }
    }

    // Companies accept either an id or a plain name; a new name is created.
    foreach (['developer', 'publisher'] as $role) {
        if ($has($role . '_id')) {
            $data[$role . '_id'] = $in[$role . '_id'] === null ? null : (int) $in[$role . '_id'];
            if ($data[$role . '_id'] !== null && one('SELECT id FROM companies WHERE id = ?', [$data[$role . '_id']]) === null) {
                $errors[$role . '_id'] = 'No company with that id.';
            }
        } elseif ($has($role . '_name')) {
            $data[$role . '_id'] = company_id_for_name(
                $in[$role . '_name'] === null ? null : (string) $in[$role . '_name']
            );
        }
    }

    if ($has('release_year')) {
        $data['release_year'] = $in['release_year'] === null ? null : (int) $in['release_year'];
        if ($data['release_year'] !== null && ($data['release_year'] < 1950 || $data['release_year'] > (int) date('Y') + 1)) {
            $errors['release_year'] = 'Between 1950 and next year.';
        }
    }
    foreach (['release_date', 'acquired_on', 'lent_on', 'sold_on', 'valued_on'] as $dateKey) {
        if ($has($dateKey)) {
            $v = $in[$dateKey];
            $data[$dateKey] = ($v === null || $v === '') ? null : (string) $v;
            if ($data[$dateKey] !== null && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $data[$dateKey])) {
                $errors[$dateKey] = 'Use YYYY-MM-DD.';
            }
        }
    }
    if ($has('rating')) {
        $data['rating'] = $in['rating'] === null ? null : (int) $in['rating'];
        if ($data['rating'] !== null && ($data['rating'] < 1 || $data['rating'] > 10)) {
            $errors['rating'] = 'Between 1 and 10.';
        }
    }
    if ($has('condition')) {
        $data['condition_grade'] = (string) $in['condition'];
        if (!in_array($data['condition_grade'], condition_options(), true)) {
            $errors['condition'] = 'Not a known condition grade.';
        }
    }
    if ($has('completeness')) {
        $data['completeness'] = (string) $in['completeness'];
        if (!in_array($data['completeness'], completeness_options(), true)) {
            $errors['completeness'] = 'Not a known completeness value.';
        }
    }
    if ($has('status')) {
        $data['status'] = (string) $in['status'];
        if (!in_array($data['status'], status_options(), true)) {
            $errors['status'] = 'Not a known status.';
        }
    }
    // Component grades arrive either nested under "components" or flattened.
    $components = is_array($in['components'] ?? null) ? $in['components'] : [];
    foreach (['box', 'manual', 'media'] as $part) {
        $value = $components[$part] ?? ($in['condition_' . $part] ?? null);
        if ($value === null) {
            continue;
        }
        $value = (string) $value;
        if (!in_array($value, component_condition_options(), true)) {
            $errors['condition_' . $part] = 'Not a known grade.';
            continue;
        }
        $data['condition_' . $part] = $value;
    }
    if ($has('copies')) {
        $data['copies'] = max(1, min(255, (int) $in['copies']));
    }
    if ($has('media_count')) {
        $data['media_count'] = max(1, min(255, (int) $in['media_count']));
    }
    foreach (['acquired_price', 'current_value', 'sold_price'] as $moneyKey) {
        if ($has($moneyKey)) {
            $v = $in[$moneyKey];
            $data[$moneyKey] = ($v === null || $v === '') ? null : $v;
            if ($data[$moneyKey] !== null && !is_numeric($data[$moneyKey])) {
                $errors[$moneyKey] = 'Must be a number.';
            }
        }
    }
    if ($has('currency')) {
        $data['currency'] = mb_substr((string) $in['currency'], 0, 3);
    }
    if ($has('is_original')) {
        $data['is_original'] = filter_var($in['is_original'], FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    }
    // Older clients still send is_wishlist. It is no longer a column - status
    // is the only truth - so it is translated and then forgotten.
    if ($has('is_wishlist') && !$has('status')) {
        $data['status'] = filter_var($in['is_wishlist'], FILTER_VALIDATE_BOOLEAN) ? 'wishlist' : 'owned';
    }
    if (isset($data['external_url']) && $data['external_url'] !== null
        && !filter_var($data['external_url'], FILTER_VALIDATE_URL)) {
        $errors['external_url'] = 'Must be a full URL.';
    }

    if (!$partial) {
        foreach (['title', 'library_id', 'platform_id', 'category_id'] as $required) {
            if (!isset($data[$required]) || $data[$required] === null || $data[$required] === '' || $data[$required] === 0) {
                $errors[$required] = 'This field is required.';
            }
        }
    } elseif (array_key_exists('title', $data) && ($data['title'] === null || $data['title'] === '')) {
        $errors['title'] = 'Title cannot be emptied.';
    }

    return [$data, $errors];
}

function api_items_create(): void
{
    api_require_write();
    $in = api_body();
    [$data, $errors] = api_item_input($in, false);

    if ($errors !== []) {
        api_error('validation_failed', 'Some fields need attention.', 422, $errors);
    }
    if (!can_add_to_library((int) $data['library_id'])) {
        api_error('forbidden', 'You do not have write access to that library.', 403);
    }

    [$user] = api_require_auth();
    $data += ['currency' => config('currency'), 'is_original' => 1, 'media_count' => 1];
    $data['created_by'] = (int) $user['id'];
    // The same rule the form gets: a branch belongs to a library, and an entry
    // filed under another one - or under a template branch, which belongs to
    // none - is invisible in the tree it claims to be in. 422 rather than a
    // silent correction: a client that sent the wrong id wants to know.
    if (($data['category_id'] ?? null) !== null
        && category_for_library((int) $data['category_id'], (int) $data['library_id']) === null) {
        api_error('bad_category', 'That category does not belong to that library.', 422);
    }
    $id = insert_row('items', $data);
    record_acquisition_event($id, $data);

    if (isset($in['tags']) && is_array($in['tags'])) {
        sync_item_tags($id, implode(',', array_map('strval', $in['tags'])));
    }

    // The lists that live in their own tables. Reported rather than swallowed:
    // a client that sends a malformed media array should be told, not left
    // wondering why the entry came back without one.
    $listErrors = api_apply_item_lists($id, $in);
    if ($listErrors !== []) {
        api_error('validation_failed', 'Some fields need attention.', 422, $listErrors);
    }

    api_ok(item_to_api(find_item($id), true), null, 201, [
        'Location' => base_url() . '/api/v1/items/' . $id,
    ]);
}

function api_items_update(int $id): void
{
    api_require_write();
    $existing = find_item($id);
    if ($existing === null || !can_read_item($existing)) {
        api_error('not_found', 'No catalogue entry with that id.', 404);
    }
    if (!can_write_item($existing)) {
        api_error('forbidden', 'That library is read-only for your account.', 403);
    }
    $in = api_body();
    [$data, $errors] = api_item_input($in, true);

    if ($errors !== []) {
        api_error('validation_failed', 'Some fields need attention.', 422, $errors);
    }
    if (isset($data['library_id']) && !can_add_to_library((int) $data['library_id'])) {
        api_error('forbidden', 'You do not have write access to the library you are moving this into.', 403);
    }
    if ($data !== []) {
        record_value_change($id, $existing, $data);
        update_row('items', $id, $data);
    }
    if (isset($in['tags']) && is_array($in['tags'])) {
        sync_item_tags($id, implode(',', array_map('strval', $in['tags'])));
    }

    // The lists that live in their own tables. Reported rather than swallowed:
    // a client that sends a malformed media array should be told, not left
    // wondering why the entry came back without one.
    $listErrors = api_apply_item_lists($id, $in);
    if ($listErrors !== []) {
        api_error('validation_failed', 'Some fields need attention.', 422, $listErrors);
    }

    api_ok(item_to_api(find_item($id), true));
}

function api_items_delete(int $id): void
{
    api_require_write();
    $item = one('SELECT id, library_id, created_by FROM items WHERE id = ? AND deleted_at IS NULL', [$id]);
    if ($item === null || !can_read_library((int) $item['library_id'])) {
        api_error('not_found', 'No catalogue entry with that id.', 404);
    }
    if (!can_delete_item($item)) {
        api_error('forbidden', 'That library is read-only for your account.', 403);
    }
    $libraryId = (int) $item['library_id'];
    foreach (all('SELECT id FROM item_images WHERE item_id = ?', [$id]) as $img) {
        record_tombstone('item_images', (int) $img['id'], $libraryId);
    }
    delete_all_item_images($id);
    delete_row('items', $id);
    record_tombstone('items', $id, $libraryId);
    api_no_content();
}

// --- Images -----------------------------------------------------------------

function api_item_images_index(int $itemId): void
{
    api_require_auth();
    $parent = one('SELECT library_id FROM items WHERE id = ? AND deleted_at IS NULL', [$itemId]);
    if ($parent === null || !can_read_library((int) $parent['library_id'])) {
        api_error('not_found', 'No catalogue entry with that id.', 404);
    }
    api_ok(array_map('image_to_api', item_images($itemId)));
}

/**
 * Upload one or more photos. Accepts multipart with "file" or "images[]",
 * or a JSON body with base64 payloads, which is easier from a mobile client
 * that already holds the image in memory.
 */
function api_item_images_upload(int $itemId): void
{
    api_require_write();
    api_guard_image_write($itemId);

    $kind = $_POST['kind'] ?? $_GET['kind'] ?? 'other';
    $before = array_column(item_images($itemId), 'id');

    $stored = 0;
    $errors = [];

    if (!empty($_FILES)) {
        $field = isset($_FILES['file']) ? 'file' : (isset($_FILES['images']) ? 'images' : null);
        if ($field === null) {
            api_error('validation_failed', 'Send the photo as a multipart field named "file".', 422);
        }
        [$stored, $errors] = store_item_images($itemId, $field, (string) $kind);
    } else {
        $in = api_body();
        if (!isset($in['file_base64'])) {
            api_error('validation_failed', 'Send multipart form data with a "file" field, or JSON with "file_base64".', 422);
        }
        [$stored, $errors] = api_store_base64_image(
            $itemId,
            (string) $in['file_base64'],
            (string) ($in['kind'] ?? $kind),
            isset($in['filename']) ? (string) $in['filename'] : null,
            isset($in['caption']) ? (string) $in['caption'] : null
        );
    }

    if ($stored === 0) {
        api_error('upload_failed', $errors[0] ?? 'Nothing was stored.', 422, ['errors' => $errors]);
    }

    $new = array_values(array_filter(
        item_images($itemId),
        fn($img) => !in_array($img['id'], $before, true)
    ));

    api_ok(array_map('image_to_api', $new), $errors === [] ? null : ['warnings' => $errors], 201);
}

/** Decode and store a base64 photo. Returns [storedCount, errors]. */
function api_store_base64_image(int $itemId, string $b64, string $kind, ?string $filename, ?string $caption): array
{
    // Tolerate a data: URL prefix.
    if (preg_match('#^data:[^;]+;base64,#', $b64)) {
        $b64 = (string) preg_replace('#^data:[^;]+;base64,#', '', $b64);
    }
    $binary = base64_decode(strtr(trim($b64), ' ', '+'), true);
    if ($binary === false || $binary === '') {
        return [0, ['file_base64 is not valid base64.']];
    }
    $max = (int) config('uploads.max_bytes');
    if (strlen($binary) > $max) {
        return [0, [sprintf('Image is %.1f MB, over the %.0f MB limit.', strlen($binary) / 1048576, $max / 1048576)]];
    }

    $tmp = tempnam(sys_get_temp_dir(), 'rv');
    if ($tmp === false || file_put_contents($tmp, $binary) === false) {
        return [0, ['Could not buffer the upload on the server.']];
    }

    $info = @getimagesize($tmp);
    $allowed = config('uploads.allowed');
    if ($info === false || !isset($allowed[$info['mime']])) {
        @unlink($tmp);
        return [0, ['Not a supported image. Use JPEG, PNG, WebP or GIF.']];
    }

    // Same shot twice is the normal case from a phone, not an error worth
    // spending disk on.
    $hash = hash('sha256', $binary);
    if (one('SELECT id FROM item_images WHERE item_id = ? AND content_hash = ?', [$itemId, $hash]) !== null) {
        @unlink($tmp);
        return [0, ['That photo is already attached to this entry.']];
    }

    $ext      = $allowed[$info['mime']];
    $basename = $itemId . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $target   = uploads_dir() . '/' . $basename;

    if (!rename($tmp, $target)) {
        @unlink($tmp);
        return [0, ['Could not write to the uploads directory. Check permissions.']];
    }
    @chmod($target, 0644);
    make_variants($target, $basename, $info['mime']);

    $count = (int) scalar('SELECT COUNT(*) FROM item_images WHERE item_id = ?', [$itemId]);
    insert_row('item_images', [
        'item_id'       => $itemId,
        'filename'      => $basename,
        'content_hash'  => hash('sha256', $binary),
        'original_name' => $filename === null ? null : mb_substr($filename, 0, 255),
        'kind'          => in_array($kind, image_kind_options(), true) ? $kind : 'other',
        'caption'       => $caption === null || $caption === '' ? null : mb_substr($caption, 0, 255),
        'width'         => (int) $info[0],
        'height'        => (int) $info[1],
        'filesize'      => strlen($binary),
        'is_primary'    => $count === 0 ? 1 : 0,
        'sort_order'    => ($count + 1) * 10,
    ]);
    ensure_primary_image($itemId);

    return [1, []];
}

function api_images_update(int $imageId): void
{
    api_require_write();
    $img = one('SELECT * FROM item_images WHERE id = ?', [$imageId]);
    if ($img === null) {
        api_error('not_found', 'No photo with that id.', 404);
    }
    api_guard_image_write((int) $img['item_id']);
    $in = api_body();
    $data = [];

    if (array_key_exists('kind', $in)) {
        $kind = (string) $in['kind'];
        if (!in_array($kind, image_kind_options(), true)) {
            api_error('validation_failed', 'Unknown photo kind.', 422, ['kind' => 'Not a known value.']);
        }
        $data['kind'] = $kind;
    }
    if (array_key_exists('caption', $in)) {
        $data['caption'] = $in['caption'] === null || $in['caption'] === '' ? null : mb_substr((string) $in['caption'], 0, 255);
    }
    if (array_key_exists('sort_order', $in)) {
        $data['sort_order'] = (int) $in['sort_order'];
    }
    if ($data !== []) {
        update_row('item_images', $imageId, $data);
    }
    if (!empty($in['is_primary'])) {
        set_primary_image((int) $img['item_id'], $imageId);
    }

    api_ok(image_to_api(one('SELECT * FROM item_images WHERE id = ?', [$imageId])));
}

function api_images_delete(int $imageId): void
{
    api_require_write();
    $img = one('SELECT item_id FROM item_images WHERE id = ?', [$imageId]);
    if ($img === null) {
        api_error('not_found', 'No photo with that id.', 404);
    }
    $libraryId = api_guard_image_write((int) $img['item_id']);
    delete_image($imageId);
    record_tombstone('item_images', $imageId, $libraryId);
    api_no_content();
}

/** Shared guard for photo writes; returns the parent library id. */
function api_guard_image_write(int $itemId): int
{
    $parent = one('SELECT id, library_id, created_by FROM items WHERE id = ? AND deleted_at IS NULL', [$itemId]);
    if ($parent === null || !can_read_library((int) $parent['library_id'])) {
        api_error('not_found', 'No photo with that id.', 404);
    }
    if (!can_write_item($parent)) {
        api_error('forbidden', 'That library is read-only for your account.', 403);
    }
    return (int) $parent['library_id'];
}

// --- Taxonomy ---------------------------------------------------------------

/**
 * Platforms, with a count of what the caller can actually see on each.
 *
 * Platforms themselves are not access-controlled - filtering the table by
 * library membership was nonsense - but the counts hanging off them are.
 */
function api_platforms_index(): void
{
    api_require_auth();
    [$acl, $aclP] = library_filter_sql('i.library_id', ACCESS_VIEWER);

    // The ACL was applied to the item *count* only, never to which platforms
    // came back: 'FROM platforms p' with no scope returned every row on the
    // instance - template rows, and every other library's custom machines by
    // name. platforms_index() on the web side gets this right and says why
    // ("Somebody else's Sharp MZ-2500 is not anybody's business"); this did not.
    $mine = accessible_library_ids(acting_user(), ACCESS_VIEWER);
    if ($mine === []) {
        api_ok([]);
    }
    $in = implode(',', array_fill(0, count($mine), '?'));

    $rows = all(
        'SELECT p.*, v.name AS manufacturer,
                (SELECT COUNT(*) FROM items i
                  WHERE i.platform_id = p.id AND i.deleted_at IS NULL
                    AND i.status = \'owned\' AND ' . $acl . ') AS n
           FROM platforms p
      LEFT JOIN companies v ON v.id = p.vendor_id
          WHERE p.library_id IN (' . $in . ')
       ORDER BY p.name',
        array_merge($aclP, $mine)
    );
    api_ok(array_map('platform_to_api', $rows));
}

/** The libraries this account may read, which is what access is decided on. */
function api_libraries_index(): void
{
    api_require_auth();
    [$acl, $aclP] = library_filter_sql('i.library_id', ACCESS_VIEWER);
    $rows = all(
        'SELECT l.*, (SELECT COUNT(*) FROM items i
                       WHERE i.library_id = l.id AND i.deleted_at IS NULL AND ' . $acl . ') AS n
         FROM libraries l ORDER BY l.sort_order, l.name',
        $aclP
    );
    $readable = array_flip(accessible_library_ids(acting_user(), ACCESS_VIEWER));
    $rows = array_values(array_filter($rows, fn($r) => isset($readable[(int) $r['id']])));
    api_ok(array_map('library_to_api', $rows));
}

/** Canonical titles, for a client building an entry form. */
function api_titles_index(): void
{
    api_require_auth();
    $q          = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : '';
    $platformId = api_query_int('platform_id');
    api_ok(array_map('title_to_api', search_titles($q, $platformId, 100)));
}

function api_titles_create(): void
{
    api_require_write();
    $in = api_body();
    [$id, $errors] = save_title(null, [
        'name'         => (string) ($in['name'] ?? ''),
        'subtitle'     => $in['subtitle'] ?? null,
        'sort_name'    => $in['sort_name'] ?? null,
        'platform_id'  => (int) ($in['platform_id'] ?? 0),
        'category_id'  => isset($in['category_id']) ? (int) $in['category_id'] : null,
        'developer'    => $in['developer'] ?? ($in['developer_name'] ?? null),
        'publisher'    => $in['publisher'] ?? ($in['publisher_name'] ?? null),
        'release_year' => isset($in['release_year']) ? (int) $in['release_year'] : null,
        'release_date' => $in['release_date'] ?? null,
        'language'     => $in['language'] ?? null,
        'region'       => $in['region'] ?? null,
        'external_url' => $in['external_url'] ?? null,
        'synopsis'     => $in['synopsis'] ?? null,
    ]);
    if ($errors !== []) {
        api_error('validation_failed', 'Some fields need attention.', 422, $errors);
    }
    api_ok(title_to_api(find_title((int) $id)), null, 201);
}

function api_categories_index(): void
{
    api_require_auth();

    // Filters, because the tree is thousands of rows: one per kind per machine. A
    // client asking "what can I file an Amiga game under" should not have to fetch
    // every branch of every platform and sort it out itself.
    //
    //   ?domain=software   the software side
    //   ?parent_id=17      the children of one node - a genre list, among other things
    //   ?platform_id=4     one machine's branches
    //   ?role=machine      machine kinds, peripheral kinds, or neither
    $rows = all_categories();

    $domain = (string) ($_GET['domain'] ?? '');
    if ($domain === 'software' || $domain === 'hardware') {
        $rows = array_values(array_filter($rows, fn($c) => (string) $c['domain'] === $domain));
    }
    if (isset($_GET['parent_id'])) {
        $pid  = (int) $_GET['parent_id'];
        $rows = array_values(array_filter(
            $rows,
            fn($c) => (int) ($c['parent_id'] ?? 0) === $pid
        ));
    }
    if (isset($_GET['platform_id'])) {
        $plid = (int) $_GET['platform_id'];
        $rows = array_values(array_filter(
            $rows,
            fn($c) => (int) ($c['platform_id'] ?? 0) === $plid
        ));
    }
    $role = (string) ($_GET['role'] ?? '');
    if (in_array($role, ['machine', 'peripheral', 'other'], true)) {
        $rows = array_values(array_filter($rows, fn($c) => (string) $c['role'] === $role));
    }

    api_ok(array_map('category_to_api', $rows));
}


function api_companies_index(): void
{
    api_require_auth();
    $q = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : '';
    if ($q !== '') {
        $rows = all('SELECT * FROM companies WHERE name LIKE ? ORDER BY name LIMIT 100', ['%' . $q . '%']);
    } else {
        $rows = all_companies();
    }
    api_ok(array_map('company_to_api', $rows));
}

function api_companies_show(int $id): void
{
    api_require_auth();
    $c = one('SELECT * FROM companies WHERE id = ?', [$id]);
    if ($c === null) {
        api_error('not_found', 'No company with that id.', 404);
    }
    [$acl, $aclP] = library_filter_sql('library_id', ACCESS_VIEWER);
    $out = company_to_api($c);
    $out['developed'] = array_map(
        fn($r) => item_to_api($r),
        all('SELECT * FROM v_items WHERE developer_id = ? AND ' . $acl . ' ORDER BY release_year, title', array_merge([$id], $aclP))
    );
    $out['published'] = array_map(
        fn($r) => item_to_api($r),
        all('SELECT * FROM v_items WHERE publisher_id = ? AND (developer_id IS NULL OR developer_id <> ?) AND ' . $acl . ' ORDER BY release_year, title',
            array_merge([$id, $id], $aclP))
    );
    api_ok($out);
}

function api_tags_index(): void
{
    api_require_auth();
    api_ok(array_map(
        fn($t) => ['id' => (int) $t['id'], 'name' => $t['name'], 'slug' => $t['slug']],
        all_tags()
    ));
}

/** Create a lookup row. Handy for a client that lets you add a library on the fly. */
function api_taxonomy_create(string $type): void
{
    [$user] = api_require_write();
    // No 'genres': a genre is a category, created through /api/v1/categories with a
    // parent. One collection, because there is one mechanism.
    $tables = ['platforms' => 'platforms', 'categories' => 'categories', 'companies' => 'companies', 'tags' => 'tags'];
    // Creating a library is a membership-bearing act and goes through
    // /libraries, not through the generic taxonomy endpoint.
    if ($type === 'libraries') {
        api_error('not_found', 'Create libraries through the web interface; they carry membership.', 404);
    }
    if (!isset($tables[$type])) {
        api_error('not_found', 'No such collection.', 404);
    }

    // The same bar the browser has to clear. Contributor was enough here for
    // everything, while the web insists on more for two of these - so a token
    // scoped to write could reshape the filing tree that every library shares,
    // which no account can do through the interface. The two surfaces are the
    // same application and must not disagree about who may do what.
    //
    //   categories, genres   the shared tree: /manage/tree is require_admin
    //   platforms            library-scoped: /manage/platforms needs ownership
    //   companies, tags      /manage/<t> is require_edit, which is this
    if ($type === 'categories' && ($user['role'] ?? '') !== 'admin') {
        api_error(
            'forbidden',
            'The filing tree is shared by every library, so only an administrator may add to it.',
            403
        );
    }

    $in = api_body();
    $name = trim((string) ($in['name'] ?? ''));
    if ($name === '') {
        api_error('validation_failed', 'A name is required.', 422, ['name' => 'Required.']);
    }

    $data = ['name' => mb_substr($name, 0, 160), 'slug' => unique_slug($type, slugify($name))];

    if ($type === 'platforms') {
        // A library, always, and one this account owns - the same rule
        // platforms_manage_save() applies. Without it this wrote library_id NULL,
        // which since the redesign means "template": a row copied into libraries
        // when they are created and visible in none of them. The endpoint
        // reported 201 and the platform appeared nowhere.
        $libraryId = isset($in['library_id']) ? (int) $in['library_id'] : 0;
        if ($libraryId <= 0) {
            api_error('validation_failed', 'Say which library the machine belongs to.', 422,
                      ['library_id' => 'Required.']);
        }
        if (!can_own_library($libraryId)) {
            api_error('forbidden', 'That library is not yours to add machines to.', 403);
        }
        $data['library_id'] = $libraryId;

        // 'manufacturer' is a read alias built by LEFT JOIN companies, and
        // sort_order went in migration 0005. Writing either threw an uncaught
        // PDOException, so this endpoint could never create a platform.
        $vendorId = isset($in['vendor_id']) ? (int) $in['vendor_id'] : 0;
        if ($vendorId > 0) {
            $vendor = one('SELECT id, library_id FROM companies WHERE id = ?', [$vendorId]);
            if ($vendor === null || (int) $vendor['library_id'] !== $libraryId) {
                api_error('validation_failed', 'That maker is not one you can use.', 422,
                          ['vendor_id' => 'Unknown maker.']);
            }
            $data['vendor_id'] = $vendorId;
        }
        $data['year_introduced'] = isset($in['year_introduced']) ? (int) $in['year_introduced'] : null;
        $data['accent_color']    = isset($in['color']) && preg_match('/^#[0-9a-fA-F]{6}$/', (string) $in['color'])
            ? (string) $in['color'] : '#cba6f7';
    } elseif ($type === 'categories') {
        // parent_id is what makes a genre: a category under Games is a genre, one
        // under Applications › Productivity is a kind of application. Same field.
        $parent = isset($in['parent_id']) ? (int) $in['parent_id'] : 0;
        if ($parent > 0) {
            $row = one('SELECT id, domain FROM categories WHERE id = ?', [$parent]);
            if ($row === null) {
                api_error('validation_failed', 'No category with that parent id.', 422,
                          ['parent_id' => 'Unknown category.']);
            }
            $data['parent_id'] = $parent;
            $data['domain']    = (string) $row['domain'];
        } else {
            $data['domain'] = in_array((string) ($in['domain'] ?? 'software'), ['software', 'hardware'], true)
                ? (string) $in['domain'] : 'software';
        }
        $data['role']       = 'other';
        $data['sort_order'] = isset($in['sort_order']) ? (int) $in['sort_order'] : 0;
    } elseif ($type === 'companies') {
        foreach (['country', 'website', 'wikipedia_url', 'notes'] as $k) {
            $data[$k] = isset($in[$k]) ? (string) $in[$k] : null;
        }
        $data['founded_year'] = isset($in['founded_year']) ? (int) $in['founded_year'] : null;
    }

    $id = insert_row($type, $data);
    $row = one("SELECT * FROM `$type` WHERE id = ?", [$id]);

    $serialiser = [
        'platforms'  => 'platform_to_api',
        'categories' => 'category_to_api',
        'companies'  => 'company_to_api',
    ][$type] ?? null;

    api_ok($serialiser ? $serialiser($row) : $row, null, 201);
}

// --- Stats and sync ---------------------------------------------------------

function api_stats(): void
{
    api_require_auth();
    [$acl, $aclP] = library_filter_sql('library_id', ACCESS_VIEWER);
    [$aclI, $iP]  = library_filter_sql('i.library_id', ACCESS_VIEWER);

    $totals = one('SELECT COUNT(*) AS items,
                          SUM(status = \'owned\') AS owned,
                          SUM(status = \'wishlist\') AS wanted,
                          SUM(status = \'lent\') AS lent,
                          SUM(status = \'sold\') AS sold,
                          SUM(acquired_price) AS spend,
                          SUM(current_value) AS value,
                          SUM(sold_price) AS recouped,
                          AVG(NULLIF(rating,0)) AS avg_rating,
                          MIN(NULLIF(release_year,0)) AS earliest, MAX(release_year) AS latest
                   FROM items WHERE deleted_at IS NULL AND ' . $acl, $aclP) ?? [];

    api_ok([
        'items'          => (int) ($totals['items'] ?? 0),
        'owned'          => (int) ($totals['owned'] ?? 0),
        'wishlist'       => (int) ($totals['wanted'] ?? 0),
        'lent'           => (int) ($totals['lent'] ?? 0),
        'sold'           => (int) ($totals['sold'] ?? 0),
        'photos'         => (int) scalar('SELECT COUNT(*) FROM item_images img JOIN items i ON i.id = img.item_id
                                          WHERE i.deleted_at IS NULL AND ' . $aclI, $iP),
        'total_spend'    => $totals['spend'] === null ? null : (float) $totals['spend'],
        'total_value'    => $totals['value'] === null ? null : (float) $totals['value'],
        'total_recouped' => $totals['recouped'] === null ? null : (float) $totals['recouped'],
        'currency'       => config('currency'),
        'average_rating' => $totals['avg_rating'] === null ? null : round((float) $totals['avg_rating'], 2),
        'year_range'     => [
            'from' => $totals['earliest'] === null ? null : (int) $totals['earliest'],
            'to'   => $totals['latest'] === null ? null : (int) $totals['latest'],
        ],
        'by_library' => all('SELECT l.id, l.name, l.slug, l.accent_color AS color, COUNT(i.id) AS count,
                                    SUM(i.current_value) AS value
                             FROM libraries l
                             LEFT JOIN items i ON i.library_id = l.id AND i.deleted_at IS NULL AND i.status = \'owned\'
                             WHERE ' . str_replace('i.library_id', 'l.id', $aclI) . '
                             GROUP BY l.id ORDER BY count DESC, l.name', $iP),
        'by_platform' => all('SELECT p.id, p.name, p.slug, p.accent_color AS color, COUNT(i.id) AS count,
                                     SUM(i.current_value) AS value
                              FROM platforms p
                              LEFT JOIN items i ON i.platform_id = p.id AND i.deleted_at IS NULL
                                               AND i.status = \'owned\' AND ' . $aclI . '
                              GROUP BY p.id HAVING count > 0 ORDER BY count DESC, p.name', $iP),
        'by_category' => all('SELECT c.id, c.name, c.slug, c.domain, COUNT(i.id) AS count
                              FROM categories c
                              LEFT JOIN items i ON i.category_id = c.id AND i.deleted_at IS NULL
                                               AND i.status = \'owned\' AND ' . $aclI . '
                              GROUP BY c.id HAVING count > 0 ORDER BY count DESC', $iP),
        'by_decade' => all('SELECT FLOOR(release_year/10)*10 AS decade, COUNT(*) AS count
                            FROM items WHERE deleted_at IS NULL AND release_year IS NOT NULL
                              AND status = \'owned\' AND ' . $acl . '
                            GROUP BY decade ORDER BY decade', $aclP),
        'missing' => [
            'photos'    => (int) scalar('SELECT COUNT(*) FROM v_items WHERE image_count = 0 AND ' . $acl, $aclP),
            'year'      => (int) scalar('SELECT COUNT(*) FROM v_items WHERE release_year IS NULL AND ' . $acl, $aclP),
            'developer' => (int) scalar('SELECT COUNT(*) FROM v_items WHERE developer_id IS NULL AND ' . $acl, $aclP),
            'value'     => (int) scalar('SELECT COUNT(*) FROM v_items WHERE current_value IS NULL AND status = \'owned\' AND ' . $acl, $aclP),
        ],
    ]);
}

/**
 * Barcode lookup, so a phone can scan a box and jump straight to the entry.
 * Returns the matches rather than a single item: duplicates and regional
 * variants legitimately share a barcode.
 */
function api_barcode_lookup(string $barcode): void
{
    api_require_auth();
    $barcode = trim($barcode);
    if ($barcode === '') {
        api_error('validation_failed', 'Send a barcode to look up.', 422);
    }
    [$acl, $aclP] = library_filter_sql('library_id', ACCESS_VIEWER);
    $rows = all("SELECT * FROM v_items WHERE barcode = ? AND $acl ORDER BY title", array_merge([$barcode], $aclP));

    api_ok([
        'barcode' => $barcode,
        'found'   => $rows !== [],
        'items'   => array_map(fn($r) => item_to_api($r, true), $rows),
    ]);
}

/** One entry at random from what the caller can see. Good for a "play this" button. */
function api_items_random(): void
{
    api_require_auth();
    [$where, $params] = build_item_filters($_GET);
    $row = one("SELECT * FROM v_items WHERE $where ORDER BY RAND() LIMIT 1", $params);
    if ($row === null) {
        api_error('not_found', 'Nothing matches those filters.', 404);
    }
    api_ok(item_to_api($row, true));
}

/**
 * Create several entries in one request. Bulk-adding from a barcode scanning
 * session over a mobile connection is painful one round trip at a time.
 * Partial success is normal, so each result reports its own outcome.
 */
function api_items_bulk(): void
{
    [$bulkUser] = api_require_write();
    $in = api_body();
    $rows = $in['items'] ?? null;
    if (!is_array($rows) || $rows === []) {
        api_error('validation_failed', 'Send an "items" array.', 422);
    }
    if (count($rows) > 100) {
        api_error('validation_failed', 'Send at most 100 entries per request.', 422);
    }

    $results  = [];
    $created  = 0;
    foreach ($rows as $index => $row) {
        if (!is_array($row)) {
            $results[] = ['index' => $index, 'ok' => false, 'error' => 'Not an object.'];
            continue;
        }
        [$data, $errors] = api_item_input($row, false);
        if ($errors !== []) {
            $results[] = ['index' => $index, 'ok' => false, 'error' => 'validation_failed', 'details' => $errors];
            continue;
        }
        if (!can_add_to_library((int) $data['library_id'])) {
            $results[] = ['index' => $index, 'ok' => false, 'error' => 'forbidden'];
            continue;
        }
        // Per row, not per batch: one bad category should cost that row and not
        // the nine good ones beside it.
        if (($data['category_id'] ?? null) !== null
            && category_for_library((int) $data['category_id'], (int) $data['library_id']) === null) {
            $results[] = ['index' => $index, 'ok' => false, 'error' => 'bad_category'];
            continue;
        }
        $data += ['currency' => config('currency'), 'is_original' => 1, 'media_count' => 1];
        $data['created_by'] = (int) $bulkUser['id'];
        $id = insert_row('items', $data);
        record_acquisition_event($id, $data);
        if (isset($row['tags']) && is_array($row['tags'])) {
            sync_item_tags($id, implode(',', array_map('strval', $row['tags'])));
        }
        $created++;
        $results[] = ['index' => $index, 'ok' => true, 'id' => $id, 'title' => $data['title']];
    }

    api_ok($results, ['created' => $created, 'failed' => count($rows) - $created], $created > 0 ? 201 : 422);
}

/**
 * Delta sync for offline clients.
 *
 * Pass the server_time from the previous response back as ?since=. The first
 * call omits it and receives everything. Deletions come back as tombstones,
 * because a client cannot infer them from a list of changed rows.
 */
function api_sync(): void
{
    api_require_auth();

    $since = isset($_GET['since']) && is_string($_GET['since']) ? trim($_GET['since']) : '';
    $sinceSql = null;
    if ($since !== '') {
        $ts = api_parse_datetime($since);
        if ($ts === null) {
            api_error('validation_failed', 'since must be an ISO 8601 timestamp, for example 2026-07-25T09:30:00Z.', 422);
        }
        $sinceSql = date('Y-m-d H:i:s', $ts);
    }

    // Captured before the reads, so anything written mid-request is picked up
    // by the next sync rather than being missed entirely.
    $serverTime = gmdate('Y-m-d\TH:i:s\Z');

    [$acl, $aclP]      = library_filter_sql('library_id', ACCESS_VIEWER);
    [$tombAcl, $tombP] = library_filter_sql('library_id', ACCESS_VIEWER);

    if ($sinceSql === null) {
        $changed = all("SELECT * FROM v_items WHERE $acl ORDER BY id", $aclP);
        $deleted = ['items' => [], 'item_images' => []];
    } else {
        $changed = all("SELECT * FROM v_items WHERE updated_at > ? AND $acl ORDER BY id", array_merge([$sinceSql], $aclP));
        // A tombstone with no library recorded predates access control, so it
        // is only reported to users who can see everything.
        $rows = all(
            "SELECT entity, entity_id FROM tombstones
             WHERE deleted_at > ? AND (library_id IS NOT NULL AND $tombAcl)",
            array_merge([$sinceSql], $tombP)
        );
        $deleted = ['items' => [], 'item_images' => []];
        foreach ($rows as $r) {
            if (isset($deleted[$r['entity']])) {
                $deleted[$r['entity']][] = (int) $r['entity_id'];
            }
        }
    }

    api_ok([
        'server_time' => $serverTime,
        'since'       => $since === '' ? null : api_datetime($sinceSql),
        'full_sync'   => $sinceSql === null,
        'items'       => array_map(fn($r) => item_to_api($r, true), $changed),
        'deleted'     => $deleted,
        'libraries'   => array_map('library_to_api', readable_libraries()),
        'platforms'   => array_map('platform_to_api', all_platforms()),
        'categories'  => array_map('category_to_api', all_categories()),
        'companies'   => array_map('company_to_api', all_companies()),
        // Titles the caller's entries actually point at. Sending the whole
        // table would grow without bound; this is exactly what a client needs
        // to render what it just received.
        'titles'      => array_map('title_to_api', titles_for_items(array_column($changed, 'title_id'))),
    ], [
        'items_changed' => count($changed),
        'items_deleted' => count($deleted['items']),
    ]);
}

/**
 * Metadata lookup for native clients: same providers, same normalised shape.
 * Read-only - applying a suggestion goes through the ordinary item update.
 */
function api_metadata_search(): void
{
    api_require_write();
    $title = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : '';
    if ($title === '') {
        api_error('validation_failed', 'Pass ?q= with a title to search for.', 422);
    }
    // A platform is not an access boundary, so there is nothing to check here
    // beyond it existing. What the caller may then do with a result is decided
    // when they write it to a library.
    $platformId = api_query_int('platform_id');
    if ($platformId !== null && one('SELECT id FROM platforms WHERE id = ?', [$platformId]) === null) {
        api_error('validation_failed', 'No platform with that id.', 422);
    }

    $out = metadata_search_all($title, $platformId);
    api_ok($out['results'], [
        'query'    => $title,
        'count'    => count($out['results']),
        'errors'   => $out['errors'],
        'providers' => array_map(
            fn($p) => ['id' => (int) $p['id'], 'name' => $p['name'], 'type' => $p['type']],
            enabled_metadata_providers()
        ),
    ]);
}

// ---------------------------------------------------------------------------
// Notifications, for native clients
//
// Written for a phone that has been in a pocket for a week: it holds the
// timestamp of the last notice it saw, asks for everything after it, and gets
// back rows it can render without a second call. `unread` comes with every
// response so a badge can be drawn from one request.
//
// Reading is not writing, so a read-only token can poll this; marking things
// read is a write, because it changes what other clients will see.
// ---------------------------------------------------------------------------

function api_notifications_index(): void
{
    // api_identify() hands back [$user, $token] and may hand back null, so it
    // cannot stand in for the check: reading it as a user row looked right and
    // asked the database for $user['id'] on a two-element list. There is no
    // api_require_read() either - reading is what api_require_auth() allows,
    // and a read-only token is refused only by api_require_write().
    [$user] = api_require_auth();

    $since  = trim((string) ($_GET['since'] ?? ''));
    $unread = isset($_GET['unread']) && $_GET['unread'] !== '0';
    $limit  = max(1, min(200, (int) ($_GET['limit'] ?? 50)));

    if ($since !== '' && strtotime($since) === false) {
        api_error('validation_failed', 'since must be a timestamp the server can read.', 422);
    }

    $rows = notifications_for((int) $user['id'], $limit, $since ?: null, $unread);

    // api_ok($data, $meta) builds the envelope itself. Passing an envelope to it
    // wrapped a second one round the first, so this endpoint alone answered
    // {"data":{"data":[...],"meta":{...}}} while every other one answers
    // {"data":[...],"meta":{...}} - which is also what docs/openapi.yaml says.
    api_ok(
        array_map('notification_to_api', $rows),
        [
            'unread' => unread_notification_count((int) $user['id']),
            // What to send as `since` next time. Taken from the newest row
            // rather than from the clock, so nothing written during this
            // request is skipped.
            'cursor' => $rows === [] ? ($since ?: null) : $rows[0]['created_at'],
        ]
    );
}

function api_notifications_read(): void
{
    [$user] = api_require_write();

    // api_body(), not api_json_body(): the body is read the same way whether it
    // arrived as JSON or as form fields, and a native client that posts a form
    // should be able to mark a notice read like any other.
    $payload = api_body();
    $ids     = $payload['ids'] ?? null;

    if ($ids === 'all' || (is_array($ids) && $ids === [])) {
        $n = mark_all_notifications_read((int) $user['id']);
        api_ok(['marked' => $n, 'unread' => 0]);
    }

    if (!is_array($ids)) {
        api_error('validation_failed', 'Send ids as an array, or "all".', 422);
    }

    $marked = 0;
    foreach (array_slice($ids, 0, 200) as $id) {
        if ((int) $id > 0) {
            mark_notification_read((int) $user['id'], (int) $id);
            $marked++;
        }
    }

    api_ok([
        'marked' => $marked,
        'unread' => unread_notification_count((int) $user['id']),
    ]);
}

