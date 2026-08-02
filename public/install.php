<?php
declare(strict_types=1);

/**
 * RetroVault web installer.
 *
 * Deliberately standalone: it does not boot the application, because the whole
 * point is that the application cannot boot yet. It requires nothing but PDO,
 * so it still runs on a server that is missing half the extensions - and can
 * therefore tell you which ones.
 *
 * DELETE THIS FILE once the install is finished. It refuses to run against a
 * configured install with accounts in it, but a file that cannot run is still
 * better removed than left lying in a document root.
 */

// Not on the command line. bin/install.php includes this file for the helpers
// below - pdo_connect(), run_sql_file(), config_php(), the requirements check -
// and wants none of the wizard. A session there would be a file in /tmp nobody
// reads, and the early return further down stops before any of the wizard runs.
// Every function in this file is still defined either way: PHP hoists
// unconditional top-level declarations when the file is compiled, not when the
// return is reached.
if (PHP_SAPI !== 'cli') {
    session_start();
}
error_reporting(E_ALL);
ini_set('display_errors', '0');

const APP_DIR      = __DIR__ . '/..';
const CONFIG_FILE  = APP_DIR . '/src/config.local.php';
const SCHEMA_FILE  = APP_DIR . '/db/schema.sql';
const SEED_FILE    = APP_DIR . '/db/seed.sql';
const UPLOADS_DIR  = __DIR__ . '/uploads';

/**
 * A path as it would be typed, not as it was assembled.
 *
 * APP_DIR is __DIR__ . '/..', so every constant built from it carries the
 * public/.. in the middle - and the installer prints those paths at somebody who
 * then has to find the file. "/srv/www/vhosts/x/public/../src/config.local.php"
 * is correct and is not an answer to "where is it".
 *
 * The directory is resolved rather than the file: this is used before the file
 * exists as well as after, and realpath() on something not yet written returns
 * false.
 */
function pretty_path(string $path): string
{
    $dir  = realpath(dirname($path));
    return $dir === false ? $path : $dir . '/' . basename($path);
}

/**
 * A count and the word for it.
 *
 * "1 accounts" was on the finished-installing page, which is a small thing that
 * makes a page look unread.
 */
function counted(int $n, string $one, string $many): string
{
    return $n . ' ' . ($n === 1 ? $one : $many);
}

// --- Small helpers ----------------------------------------------------------

function h($v): string
{
    return htmlspecialchars((string) $v, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function post(string $key, string $default = ''): string
{
    $v = $_POST[$key] ?? $default;
    return is_string($v) ? trim($v) : $default;
}

/**
 * Which steps can be jumped to.
 *
 * Nothing before the last one changes anything, so going back to correct a
 * decision is free. A step opens as soon as the one before it has been
 * answered - not merely visited, which would let somebody skip past a choice
 * and reach the apply step with nothing decided.
 */
/**
 * The stages the install page shows, in the order they happen.
 *
 * Named here so the page and the code that ticks them cannot drift apart.
 */
function install_stages(): array
{
    return [
        'start'   => 'Connecting to the database',
        'db'      => 'Preparing the database',
        'schema'  => 'Building the structure',
        'config'  => 'Writing the configuration',
        'starter' => 'Fetching the starter data',
        'admin'   => 'Creating the administrator and first library',
        'done'    => 'Finishing',
    ];
}

/** The progress list, sent before any work starts. */
function install_progress_shell(): string
{
    $out = '<div class="installrun" id="installrun"><p class="label" style="margin:0 0 .6rem">Installing</p><ul class="installrun__steps">';
    foreach (install_stages() as $key => $label) {
        $out .= '<li id="stage-' . h($key) . '">' . h($label) . '</li>';
    }
    $out .= '</ul><p class="hint" style="margin:.6rem 0 0">Do not reload the page.</p></div>';

    // Stages are queued and shown at a readable pace, rather than the server sleeping
    // between them. Half the work finishes in milliseconds - the database, the schema,
    // the config file - so without this those four flash past and the whole thing
    // looks like one long pause on "Fetching the starter data".
    //
    // The delay is in the display only. The install runs at full speed and the queue
    // drains alongside it, so this costs nothing except at the very end, where it
    // waits for the last stage to have been seen before clearing.
    $out .= '<script>
(function () {
  var q = [], busy = false, DWELL = 420, prev = null, drained = null;
  function apply(t) {
    if (prev) { var p = document.getElementById("stage-" + prev); if (p) { p.className = "is-done"; } }
    var e = document.getElementById("stage-" + t.key);
    if (e) {
      e.className = "is-now";
      if (t.note) { e.innerHTML += \' <span class="hint">\' + t.note + "</span>"; }
    }
    prev = t.key;
  }
  function drain() {
    if (!q.length) { busy = false; if (drained) { drained(); } return; }
    busy = true;
    apply(q.shift());
    setTimeout(drain, DWELL);
  }
  window.__rvTick = function (key, note) { q.push({ key: key, note: note }); if (!busy) { drain(); } };
  // Called once the server has finished: mark the last stage done and clear the panel,
  // but only after everything queued has actually been on screen.
  window.__rvDone = function () {
    drained = function () {
      if (prev) { var p = document.getElementById("stage-" + prev); if (p) { p.className = "is-done"; } }
      setTimeout(function () {
        var r = document.getElementById("installrun");
        if (r) { r.remove(); }
        var res = document.getElementById("installresult");
        if (res) { res.removeAttribute("hidden"); }
      }, DWELL);
    };
    if (!busy) { drained(); }
  };
})();
</script>';

    // Padding, because some proxies will not forward anything until they have a few
    // kilobytes. Costs nothing and is the difference between a live page and a blank
    // one on a default nginx.
    return $out . '<!--' . str_repeat(' ', 4096) . '-->';
}

/**
 * Mark a stage as running, and the one before it as done.
 *
 * Real progress: each call happens when that part of the work actually begins, and is
 * flushed immediately. Nothing here is on a timer.
 */
function install_tick(string $key, ?string $note = null): void
{
    // Enqueued rather than applied: the page decides how long each stage is visible,
    // so the server never waits on the display.
    echo '<script>window.__rvTick&&__rvTick("' . h($key) . '"'
       . ($note === null ? '' : ',"' . h($note) . '"') . ');</script>' . "\n";
    if (function_exists('ob_flush')) { @ob_flush(); }
    @flush();
}

function step_reachable(int $n): bool
{
    // Installing is a one-way door, and the stepper should say so from both sides.
    //
    // Before it starts, step 7 is not a place you can go: it is the act itself, and
    // the only way in is the button on Review. Once it has started, nothing before it
    // is reachable either - the tables are already going, so a link back to
    // "Deployment" would offer to change a decision that has been acted on.
    $started = (bool) recall('installing')
            || ((bool) recall('applied') && config_exists());
    if ($started) {
        return $n === 7;
    }

    switch ($n) {
        case 1: return true;
        case 2: return true;
        case 3: return (bool) recall('db_reached');
        case 4: return recall('deploy_action') !== null;
        case 5: return (bool) recall('settings_set');
        case 6: return (bool) recall('admin_set');
    }
    return false;
}

/** Everything the wizard has been told, ready for the apply step. */
function plan(): array
{
    return [
        'db'     => [
            'host' => (string) recall('db_host', ''), 'port' => (string) recall('db_port', '3306'),
            'name' => (string) recall('db_name', ''), 'user' => (string) recall('db_user', ''),
            'pass' => (string) recall('db_pass', ''),
        ],
        'deploy' => (string) recall('deploy_action', ''),
        'uploads_too' => (bool) recall('erase_uploads', false),
        'admin'  => (string) recall('admin_username', ''),
        'email'  => (string) recall('admin_email', ''),
        // What to do about starter data: remote, local or none.
        //
        // This was missing, so $plan['templates'] was always unset and the install
        // phase fell back to 'remote' - which meant choosing "none" on the settings
        // step loaded the templates anyway and then copied them into the library.
        // The setting was recorded, read back on the settings page, and never once
        // consulted by the thing it was supposed to control.
        'templates' => (string) recall('templates', 'remote'),
        'examples'  => (string) recall('examples', '0') === '1',
    ];
}

function step(): int
{
    // Seven: requirements, connection, deployment, settings, administrator,
    // review, install. The ceiling has to match, or the last button silently
    // redraws the previous page - which is exactly what a clamp of six did to
    // step 7 when it was added.
    return max(1, min(7, (int) ($_GET['step'] ?? $_POST['step'] ?? 1)));
}

function token(): string
{
    if (empty($_SESSION['install_csrf'])) {
        $_SESSION['install_csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['install_csrf'];
}

function check_token(): void
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        return;
    }
    if (!hash_equals(token(), (string) ($_POST['_csrf'] ?? ''))) {
        http_response_code(419);
        exit('Session expired. Reload the installer and start again.');
    }
}

/** Saved answers survive between steps without touching disk. */
function remember(array $values): void
{
    $_SESSION['install'] = array_merge($_SESSION['install'] ?? [], $values);
}

function recall(string $key, $default = null)
{
    return $_SESSION['install'][$key] ?? $default;
}

// --- Environment inspection -------------------------------------------------

/**
 * The version of RetroVault this copy is, read from src/version.php.
 *
 * Parsed rather than required, because the installer deliberately boots with
 * nothing but PDO and pulling in application files would undo that.
 */
function installer_version(): string
{
    $file = @file_get_contents(dirname(__DIR__) . '/src/version.php');
    if ($file === false) {
        return '';
    }
    return preg_match("/APP_VERSION\s*=\s*'([^']+)'/", $file, $m) ? $m[1] : '';
}

/**
 * Is there a newer release? Returns [state, latest, url, detail].
 *
 * state is 'current', 'behind', or 'unknown' - and 'unknown' is a real answer
 * rather than an error: a repository with no releases yet, or a machine with no
 * outbound HTTPS, are both perfectly normal states to install from. Nothing
 * here blocks anything.
 */
function installer_update_state(): array
{
    $running = installer_version();
    $url     = 'https://api.github.com/repos/norrorthoarders/retrovault/releases/latest';

    $ctx = stream_context_create(['http' => [
        // Short on purpose. Somebody installing behind a firewall that
        // blackholes outbound traffic should wait three seconds to be told we
        // could not check, not thirty.
        'timeout' => 3,
        'method'  => 'GET',
        'header'  => "Accept: application/vnd.github+json\r\nUser-Agent: RetroVault-installer\r\n",
        'ignore_errors' => true,
    ], 'ssl' => ['verify_peer' => true, 'verify_peer_name' => true]]);

    $body = @file_get_contents($url, false, $ctx);
    if ($body === false) {
        return ['unknown', '', '', 'the release feed could not be reached'];
    }

    $data = json_decode((string) $body, true);
    $tag  = is_array($data) ? ($data['tag_name'] ?? $data['version'] ?? null) : null;
    if ($tag === null) {
        $why = is_array($data) && !empty($data['message'])
            ? 'GitHub said: ' . $data['message']
            : 'the feed named no version';
        return ['unknown', '', '', $why];
    }

    $latest = ltrim((string) $tag, 'vV');
    if ($running === '') {
        return ['unknown', $latest, (string) ($data['html_url'] ?? ''), 'this copy does not state its own version'];
    }

    return [
        version_compare($latest, $running, '>') ? 'behind' : 'current',
        $latest,
        (string) ($data['html_url'] ?? ''),
        '',
    ];
}

/**
 * Bring the application up, once, after the configuration exists.
 *
 * The installer boots with nothing but PDO on purpose, which is right for the
 * five steps that run before there is a configuration to read. The last step is
 * different: it has just written one, and the work left - fetching starter data
 * and copying it into the first library - is application code with its own
 * dependencies.
 *
 * Requiring src/templates.php on its own was not enough, and failed at runtime
 * rather than at load: that file calls metadata_http_get() and
 * seed_library_hardware(), which live in two other files nothing had loaded.
 *
 * Returns false if the application cannot be brought up, so the caller can log
 * it and carry on rather than losing the install.
 */
function installer_boot_app(): bool
{
    static $booted = null;
    if ($booted !== null) {
        return $booted;
    }

    try {
        // APP_DIR, not dirname(__DIR__): the installer already worked out where
        // the application lives, and one answer is better than two that can
        // disagree.
        if (!defined('APP_ROOT')) {
            define('APP_ROOT', APP_DIR);
        }
        if (!defined('BASE_PATH')) {
            define('BASE_PATH', '');
        }
        foreach ([
            'helpers', 'proxy', 'db', 'auth', 'throttle', 'acl', 'log',
            'notify', 'ldap', 'metadata', 'version', 'migrate', 'images',
            'models', 'templates',
        ] as $module) {
            require_once APP_ROOT . '/src/' . $module . '.php';
        }
        // Prove it rather than assume it: a missing function here is exactly
        // the failure this replaced.
        $booted = function_exists('template_sync')
               && function_exists('seed_library_hardware')
               && function_exists('metadata_http_get');
    } catch (Throwable $e) {
        error_log('[retrovault] installer could not boot the application: ' . $e->getMessage());
        $booted = false;
    }

    return $booted;
}

function requirements(): array
{
    $r = [];

    $phpOk = version_compare(PHP_VERSION, '8.1.0', '>=');
    $r[] = [
        'name'  => 'PHP 8.1 or newer',
        'ok'    => $phpOk,
        'fatal' => true,
        'found' => PHP_VERSION,
        'fix'   => 'Install a newer PHP. The application uses syntax that will not parse on 8.0.',
    ];

    $extensions = [
        'pdo_mysql' => ['fatal' => true,  'pkg' => 'php8-mysql',    'why' => 'Connects to MariaDB. Nothing works without it.'],
        'mbstring'  => ['fatal' => true,  'pkg' => 'php8-mbstring', 'why' => 'Handles multi-byte titles safely.'],
        'gd'        => ['fatal' => false, 'pkg' => 'php8-gd',       'why' => 'Generates thumbnails. Without it every photo is served full size.'],
        'exif'      => ['fatal' => false, 'pkg' => 'php8-exif',     'why' => 'Rotates phone photos the right way up.'],
        'ldap'      => ['fatal' => false, 'pkg' => 'php8-ldap',     'why' => 'Only needed for directory sign-in. Can be added later.'],
        'curl'      => ['fatal' => false, 'pkg' => 'php8-curl',     'why' => 'Used for metadata lookups. Without it they fall back to file_get_contents, which needs allow_url_fopen.'],
        'simplexml' => ['fatal' => false, 'pkg' => 'php8-xml',      'why' => 'Only needed for CSDb metadata lookups.'],
        'dom'       => ['fatal' => false, 'pkg' => 'php8-xml',      'why' => 'Needed by the HTML-scraping sources (Amiga Hardware Database, TheRetroWeb). Without it they return nothing and log why.'],
        'json'      => ['fatal' => true,  'pkg' => 'php8',          'why' => 'Used by the API and by stored settings.'],
    ];
    foreach ($extensions as $ext => $meta) {
        $r[] = [
            'name'  => 'Extension: ' . $ext,
            'ok'    => extension_loaded($ext),
            'fatal' => $meta['fatal'],
            'found' => extension_loaded($ext) ? 'loaded' : 'missing',
            'fix'   => 'zypper install ' . $meta['pkg'] . ' (or the equivalent), then restart Apache. ' . $meta['why'],
        ];
    }

    $uploadsWritable = is_dir(UPLOADS_DIR) && is_writable(UPLOADS_DIR);
    $r[] = [
        'name'  => 'public/uploads is writable',
        'ok'    => $uploadsWritable,
        'fatal' => true,
        'found' => is_dir(UPLOADS_DIR)
            ? (($uploadsWritable ? 'writable' : 'not writable') . ' by ' . current_user_name())
            : 'directory missing',
        'fix'   => 'chown -R wwwrun:www ' . UPLOADS_DIR . ' && chmod 775 ' . UPLOADS_DIR,
    ];

    // The router only works if .htaccess is being honoured. If this file was
    // reached through a rewrite the test is moot, so check the file exists and
    // that mod_rewrite is present where we can see it.
    $rewrite = function_exists('apache_get_modules')
        ? in_array('mod_rewrite', apache_get_modules(), true)
        : null;
    $r[] = [
        'name'  => 'URL rewriting',
        'ok'    => $rewrite !== false,
        'fatal' => false,
        'found' => $rewrite === null ? 'cannot detect from this SAPI' : ($rewrite ? 'mod_rewrite loaded' : 'mod_rewrite missing'),
        'fix'   => 'Enable mod_rewrite and set AllowOverride All on the document root, otherwise every URL except the front page returns 404.',
    ];

    $r[] = [
        'name'  => 'Schema file readable',
        'ok'    => is_readable(SCHEMA_FILE),
        'fatal' => true,
        'found' => is_readable(SCHEMA_FILE) ? 'db/schema.sql' : 'missing or unreadable',
        'fix'   => 'The db/ directory must be present alongside public/.',
    ];

    $postMax   = return_bytes((string) ini_get('post_max_size'));
    $uploadMax = return_bytes((string) ini_get('upload_max_filesize'));
    $r[] = [
        'name'  => 'Upload limits',
        'ok'    => $uploadMax >= 8 * 1024 * 1024 && $postMax >= $uploadMax,
        'fatal' => false,
        'found' => 'upload_max_filesize=' . ini_get('upload_max_filesize') . ', post_max_size=' . ini_get('post_max_size'),
        'fix'   => 'Set upload_max_filesize to at least 16M and post_max_size well above it. A batch of box photos arrives in one request, and when it exceeds post_max_size PHP discards the whole body with no error.',
    ];

    return $r;
}

function current_user_name(): string
{
    if (function_exists('posix_getpwuid') && function_exists('posix_geteuid')) {
        $info = @posix_getpwuid(posix_geteuid());
        if (is_array($info) && isset($info['name'])) {
            return (string) $info['name'];
        }
    }
    return (string) (getenv('USER') ?: 'the web server user');
}

function return_bytes(string $value): int
{
    $value = trim($value);
    if ($value === '') {
        return 0;
    }
    $unit = strtolower($value[strlen($value) - 1]);
    $num  = (int) $value;
    return match ($unit) {
        'g' => $num * 1024 * 1024 * 1024,
        'm' => $num * 1024 * 1024,
        'k' => $num * 1024,
        default => $num,
    };
}

// --- Database ---------------------------------------------------------------

function pdo_connect(string $host, int $port, string $name, string $user, string $pass, bool $withDb = true): PDO
{
    $dsn = sprintf('mysql:host=%s;port=%d;%scharset=utf8mb4', $host, $port, $withDb ? "dbname=$name;" : '');
    return new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT            => 5,
    ]);
}

/**
 * Split a dump into statements without tripping over semicolons that live
 * inside strings or comments. Good enough for our own schema files, which is
 * all this needs to handle.
 */
function split_sql(string $sql): array
{
    $statements = [];
    $current    = '';
    $inString   = false;
    $quote      = '';
    $len        = strlen($sql);

    for ($i = 0; $i < $len; $i++) {
        $ch = $sql[$i];

        if ($inString) {
            $current .= $ch;
            if ($ch === '\\' && $i + 1 < $len) {
                $current .= $sql[++$i];
            } elseif ($ch === $quote) {
                $inString = false;
            }
            continue;
        }

        if ($ch === "'" || $ch === '"' || $ch === '`') {
            $inString = true;
            $quote    = $ch;
            $current .= $ch;
            continue;
        }

        // Line comments
        if (($ch === '-' && substr($sql, $i, 2) === '--') || $ch === '#') {
            $nl = strpos($sql, "\n", $i);
            $i  = $nl === false ? $len : $nl;
            // Keep the newline. Swallowing it glues the next line onto this one,
            // which makes a column following a commented line invisible to the
            // structure check.
            $current .= "\n";
            continue;
        }
        // Block comments
        if ($ch === '/' && substr($sql, $i, 2) === '/*') {
            $end = strpos($sql, '*/', $i);
            $i   = $end === false ? $len : $end + 1;
            continue;
        }

        if ($ch === ';') {
            if (trim($current) !== '') {
                $statements[] = trim($current);
            }
            $current = '';
            continue;
        }

        $current .= $ch;
    }

    if (trim($current) !== '') {
        $statements[] = trim($current);
    }
    return $statements;
}

function run_sql_file(PDO $pdo, string $file): array
{
    if (!is_readable($file)) {
        return [0, ['Cannot read ' . basename($file) . '.']];
    }
    $errors = 0;
    $messages = [];
    foreach (split_sql((string) file_get_contents($file)) as $statement) {
        try {
            $pdo->exec($statement);
        } catch (PDOException $e) {
            $errors++;
            if (count($messages) < 5) {
                $messages[] = $e->getMessage();
            }
        }
    }
    return [$errors, $messages];
}

/**
 * Tables this application owns, ordered so that dropping them front to back
 * never trips a foreign key. Anything else in the database is left alone -
 * the schema may well be sharing space with something unrelated.
 */
/**
 * Every table and view schema.sql creates, read from schema.sql.
 *
 * This used to be a list maintained by hand, and it had already drifted: it
 * named a table that has never existed and was missing several that do. A
 * reinstall that leaves tables behind is worse than one that fails outright,
 * because the next install finds a half-populated database and believes it.
 *
 * Returned child-first, which is the reverse of creation order, so dropping
 * them in sequence never trips a foreign key.
 */
function schema_objects(): array
{
    $sql = @file_get_contents(__DIR__ . '/../db/schema.sql');
    if (!is_string($sql) || $sql === '') {
        // Deliberately empty rather than a list kept by hand. A hand-kept list
        // drifts - this one already had - and half-dropping a database is worse
        // than not dropping it: the next install finds the leftovers and
        // believes them. The caller turns this into a refusal.
        return ['tables' => [], 'views' => [], 'unreadable' => true];
    }
    preg_match_all('/CREATE TABLE IF NOT EXISTS\s+`?(\w+)`?/i', $sql, $t);
    preg_match_all('/CREATE OR REPLACE VIEW\s+`?(\w+)`?/i', $sql, $v);

    return [
        'tables' => array_reverse($t[1]),
        'views'  => $v[1],
    ];
}


/** How much would be lost. Missing tables simply count as zero. */
function existing_data_counts(PDO $pdo): array
{
    $counts = [];
    // 'platforms' used to be called libraries; a library is now the thing
    // people share. Counting seed rows as though they were a collection is
    // what made an empty install report "65 libraries".
    // Singular and plural, because this is counted and then written out: one
    // account is not "1 accounts".
    foreach (['items'       => ['entry', 'entries'],
              'item_images' => ['photo', 'photos'],
              'users'       => ['account', 'accounts'],
              'libraries'   => ['library', 'libraries']] as $table => $label) {
        if (!table_exists($pdo, $table)) {
            continue;
        }
        try {
            $counts[$label[1]] = ['n' => (int) $pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn(),
                              'one' => $label[0], 'many' => $label[1]];
        } catch (PDOException $e) {
            $counts[$label] = 0;
        }
    }
    return $counts;
}

/**
 * True when somebody's work is in here, as opposed to a freshly loaded schema.
 *
 * Seeded platforms, genres and studios are structure that ships with the
 * application; losing them costs nothing. Entries, accounts and photographs are
 * the things a person would be upset to lose, so only those count.
 */
function has_real_data(array $counts): bool
{
    return ($counts['entries'] ?? 0) > 0
        || ($counts['accounts'] ?? 0) > 0
        || ($counts['photos'] ?? 0) > 0;
}

/** Is the schema loaded at all? */
function structure_present(PDO $pdo): bool
{
    return table_exists($pdo, 'items') && table_exists($pdo, 'users') && table_exists($pdo, 'libraries');
}

/**
 * Drop everything this application owns, then report what failed.
 * Deliberately not DROP DATABASE: the account may not have that right, and the
 * database may be shared with something else.
 */
/** How many of our tables are already in this database. */
function existing_object_count(PDO $pdo): array
{
    $objects = schema_objects();
    $left    = leftover_retrovault_objects($pdo, $objects);
    return ['tables' => count($left), 'names' => $left];
}

function drop_retrovault_tables(PDO $pdo): array
{
    $errors  = [];
    $objects = schema_objects();

    if (!empty($objects['unreadable'])) {
        return ['db/schema.sql could not be read, so there is no reliable list of what to drop. '
              . 'Nothing was removed. Restore the file and try again.'];
    }

    try {
        $pdo->exec('SET FOREIGN_KEY_CHECKS = 0');

        foreach ($objects['views'] as $view) {
            try {
                $pdo->exec("DROP VIEW IF EXISTS `$view`");
            } catch (PDOException $e) {
                $errors[] = $view . ': ' . $e->getMessage();
            }
        }
        foreach ($objects['tables'] as $table) {
            try {
                $pdo->exec("DROP TABLE IF EXISTS `$table`");
            } catch (PDOException $e) {
                $errors[] = $table . ': ' . $e->getMessage();
            }
        }

        // Anything of ours still standing. Dropping only a fixed list means a
        // table added since the list was written survives a "total reinstall"
        // and quietly poisons the next one, so check rather than assume.
        $left = leftover_retrovault_objects($pdo, $objects);
        foreach ($left as $name) {
            try {
                $pdo->exec("DROP TABLE IF EXISTS `$name`");
            } catch (PDOException $e) {
                $errors[] = $name . ': ' . $e->getMessage();
            }
        }
    } finally {
        try { $pdo->exec('SET FOREIGN_KEY_CHECKS = 1'); } catch (PDOException $e) { /* nothing useful to do */ }
    }

    return $errors;
}

/**
 * Tables named in schema.sql that are still present after the drop.
 *
 * Deliberately not "every table in the database": the installer promises that
 * anything else living here is untouched, and somebody pointing RetroVault at a
 * shared database should be able to believe that.
 */
function leftover_retrovault_objects(PDO $pdo, array $objects): array
{
    $known = array_map('strtolower', array_merge($objects['tables'], $objects['views']));
    if ($known === []) {
        return [];
    }
    try {
        $rows = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_NUM);
    } catch (PDOException $e) {
        return [];
    }
    $left = [];
    foreach ($rows as $row) {
        if (in_array(strtolower((string) $row[0]), $known, true)) {
            $left[] = (string) $row[0];
        }
    }
    return $left;
}

/** Remove uploaded photos, leaving the directory and its .htaccess in place. */
/**
 * Empty the uploads directory.
 *
 * Reports what it saw as well as what it removed. It used to return only the
 * count of successful unlinks, with the error suppressed - so a directory the web
 * user cannot write to came back as zero, and the installer said "No uploaded
 * files to delete" while every file was still sitting there. An erase that leaves
 * the pictures behind and calls itself clean is the wrong way round, and the
 * screen that says so is the only place anybody would have found out.
 *
 * @return array{seen:int,removed:int}
 */
function purge_uploads(): array
{
    $seen    = 0;
    $removed = 0;

    // A directory that is not there is not an empty one.
    //
    // glob() returns [] for a missing path on most systems rather than false, so
    // "there is no such directory" and "there is nothing in it" arrived at the
    // same reassuring sentence. If the uploads directory has moved - a different
    // `uploads.dir` in the configuration, a deployment that keeps it outside the
    // document root - this is what says so.
    if (!is_dir(UPLOADS_DIR)) {
        return ['seen' => 0, 'removed' => 0, 'unreadable' => true, 'missing' => true];
    }

    // glob() returning false is not "the directory is empty".
    //
    // It fails when the directory cannot be read at all - the wrong owner, or an
    // open_basedir that does not include it - and `?: []` turned that into an
    // empty list, which then reported as "no uploaded files to delete". Three
    // different situations were arriving at one reassuring sentence.
    $found = glob(UPLOADS_DIR . '/*');
    if ($found === false) {
        return ['seen' => 0, 'removed' => 0, 'unreadable' => true];
    }

    foreach ($found as $file) {
        if (!is_file($file) || str_starts_with(basename($file), '.')) {
            continue;
        }
        $seen++;
        if (@unlink($file)) {
            $removed++;
        }
    }
    return ['seen' => $seen, 'removed' => $removed, 'unreadable' => false];
}

function table_exists(PDO $pdo, string $table): bool
{
    try {
        $st = $pdo->prepare('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?');
        $st->execute([$table]);
        return (int) $st->fetchColumn() > 0;
    } catch (PDOException $e) {
        return false;
    }
}

// --- Migrations, without booting the application ---------------------------
// The installer is standalone by design, so it carries its own small version of
// what src/migrate.php does rather than requiring the app to be configured.

function installer_migration_files(): array
{
    $files = glob(APP_DIR . '/db/migrations/*.sql') ?: [];
    $names = array_map('basename', $files);
    sort($names, SORT_NATURAL);
    return $names;
}

function installer_ensure_migration_table(PDO $pdo): void
{
    $pdo->exec('CREATE TABLE IF NOT EXISTS schema_migrations (
        migration VARCHAR(190) NOT NULL, checksum CHAR(64) DEFAULT NULL,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        duration_ms INT UNSIGNED DEFAULT NULL, PRIMARY KEY (migration)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci');
}

function installer_applied_migrations(PDO $pdo): array
{
    if (!table_exists($pdo, 'schema_migrations')) {
        return [];
    }
    try {
        return $pdo->query('SELECT migration FROM schema_migrations')->fetchAll(PDO::FETCH_COLUMN) ?: [];
    } catch (PDOException $e) {
        return [];
    }
}

function installer_pending_migrations(PDO $pdo): array
{
    $applied = installer_applied_migrations($pdo);
    return array_values(array_diff(installer_migration_files(), $applied));
}

/** Record every migration as done, for a database just built from schema.sql. */
function installer_baseline(PDO $pdo): int
{
    installer_ensure_migration_table($pdo);
    $st = $pdo->prepare('INSERT IGNORE INTO schema_migrations (migration, checksum, duration_ms) VALUES (?, ?, 0)');
    $n = 0;
    foreach (installer_migration_files() as $name) {
        $file = APP_DIR . '/db/migrations/' . $name;
        $st->execute([$name, hash('sha256', (string) @file_get_contents($file))]);
        $n++;
    }
    return $n;
}

/** Apply what is outstanding. Returns [appliedNames, errors]. */
function installer_apply_migrations(PDO $pdo): array
{
    installer_ensure_migration_table($pdo);
    $done = [];
    $errors = [];
    foreach (installer_pending_migrations($pdo) as $name) {
        [$errs, $msgs] = run_sql_file($pdo, APP_DIR . '/db/migrations/' . $name);
        if ($errs > 0) {
            $errors[] = $name . ': ' . implode(' | ', $msgs);
            break;                       // stop at the first failure
        }
        $st = $pdo->prepare('INSERT INTO schema_migrations (migration, checksum, duration_ms) VALUES (?, ?, 0)
                             ON DUPLICATE KEY UPDATE applied_at = NOW()');
        $st->execute([$name, hash('sha256', (string) @file_get_contents(APP_DIR . '/db/migrations/' . $name))]);
        $done[] = $name;
    }
    return [$done, $errors];
}

/**
 * What is in this database, and therefore what should be offered.
 *
 * 'empty'   nothing of ours is there
 * 'behind'  installed, but migrations are outstanding
 * 'ready'   installed and current
 */
function installer_database_state(PDO $pdo): array
{
    $hasCore = table_exists($pdo, 'items') && table_exists($pdo, 'users');
    if (!$hasCore) {
        return ['state' => 'empty', 'counts' => [], 'pending' => [], 'version' => null];
    }

    $pending = installer_pending_migrations($pdo);
    return [
        'state'   => $pending === [] ? 'ready' : 'behind',
        'counts'  => existing_data_counts($pdo),
        'pending' => $pending,
        'version' => count(installer_applied_migrations($pdo)) . ' of ' . count(installer_migration_files()),
    ];
}

// --- Installed-state detection ---------------------------------------------

/**
 * The installer runs only when there is no configuration file.
 *
 * That is the whole rule, and it is deliberately blunt: a file on disk is
 * something only shell access can create or remove, so the gate cannot be
 * opened from a browser. Reinstalling means moving the config aside first,
 * which is a decision someone has to make at a terminal.
 */
function config_exists(): bool
{
    return is_file(CONFIG_FILE);
}

/**
 * The wizard writes the configuration at step 3 and would otherwise lock itself
 * out before step 4. This flag, set only when the installer legitimately
 * started with no config present, lets that one session finish.
 */
function wizard_is_active(): bool
{
    return (bool) recall('wizard_active');
}

/** The settings the wizard collected, in the shape config_php() expects. */
function config_values(): array
{
    return [
        'app_name'        => (string) recall('app_name', 'RetroVault'),
        'currency'        => (string) recall('currency', 'SEK'),
        'timezone'        => (string) recall('timezone', 'Europe/Stockholm'),
        'base_url'        => (string) recall('base_url', ''),
        'trusted_proxies' => (string) recall('trusted_proxies', ''),
        'db_host'         => (string) recall('db_host', '127.0.0.1'),
        'db_port'         => (string) recall('db_port', '3306'),
        'db_name'         => (string) recall('db_name', 'retrovault'),
        'db_user'         => (string) recall('db_user', 'retrovault'),
        'db_pass'         => (string) recall('db_pass', ''),
    ];
}

function config_php(array $v): string
{
    $q = fn($s) => var_export((string) $s, true);
    $proxies = array_values(array_filter(array_map('trim', explode(',', (string) ($v['trusted_proxies'] ?? '')))));
    $proxyList = $proxies === []
        ? '[]'
        : "[\n        " . implode(",\n        ", array_map($q, $proxies)) . ",\n    ]";

    return <<<PHP
<?php
declare(strict_types=1);

// Written by public/install.php on {$v['written_at']}.
// This file overrides src/config.php. Keep it out of version control.

return [
    'app_name'    => {$q($v['app_name'])},
    'app_tagline' => {$q($v['app_tagline'])},
    'currency'    => {$q($v['currency'])},
    'timezone'    => {$q($v['timezone'])},
    'debug'       => false,

    // 0/false = sign-in required to see anything.
    'public_browse' => false,

    'db' => [
        'host' => {$q($v['db_host'])},
        'port' => {$v['db_port']},
        'name' => {$q($v['db_name'])},
        'user' => {$q($v['db_user'])},
        'pass' => {$q($v['db_pass'])},
    ],

    // Absolute URL clients use. Set this when a reverse proxy terminates TLS,
    // otherwise the API hands mobile clients unreachable http:// image URLs.
    'base_url' => {$q($v['base_url'])},

    // Reverse proxies whose X-Forwarded-* headers may be believed.
    // Anything not listed here is treated as a direct client.
    'trusted_proxies' => {$proxyList},

    'api' => [
        'cors_origins' => ['*'],
        'token_days'   => 0,
    ],
];

PHP;
}

/** Rebuild the configuration text from the answers collected so far. */
function config_from_session(): string
{
    return config_php([
        'app_name'        => (string) recall('app_name', 'RetroVault'),
        'app_tagline'     => (string) recall('app_tagline', 'Retro software collection'),
        'currency'        => (string) recall('currency', 'SEK'),
        'timezone'        => (string) recall('timezone', 'Europe/Stockholm'),
        'base_url'        => (string) recall('base_url', ''),
        'trusted_proxies' => (string) recall('trusted_proxies', ''),
        // remote | local | none
        'templates'       => (string) recall('templates', 'remote'),
        // Separate from the templates choice: reference data and examples are two
        // decisions, and bundling them meant wanting one forced the other.
        'examples'        => (string) recall('examples', '0'),
        'db_host'         => (string) recall('db_host', ''),
        'db_port'         => (int) recall('db_port', 3306),
        'db_name'         => (string) recall('db_name', ''),
        'db_user'         => (string) recall('db_user', ''),
        'db_pass'         => (string) recall('db_pass', ''),
        'written_at'      => date('Y-m-d H:i'),
    ]);
}

// --- Page shell -------------------------------------------------------------

function head(string $title): void
{
    $step = step();
    ?><!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark">
<title><?= h($title) ?> · RetroVault installer</title>
<link rel="stylesheet" href="assets/css/app.css?v=<?= h((string) @filemtime(__DIR__ . '/assets/css/app.css')) ?>">
<style>
    /* A statement of fact above the checks: not an error, and not something to
       dismiss. Colour carries the severity; the border carries the eye. */
    .note {
      border-left: 3px solid #45475a;
      background: #181825;
      border-radius: 10px;
      padding: .8rem 1rem;
      margin: 0 0 1.25rem;
      font-size: .92rem;
      line-height: 1.55;
    }
    .note--warn { border-left-color: #f9e2af; }
    .note--ok   { border-left-color: #a6e3a1; }

  .wiz { max-width: 860px; margin: 0 auto; padding: 2rem 1.25rem 4rem; }
  .steps { display: flex; gap: .4rem; flex-wrap: wrap; margin-bottom: 2rem; list-style: none; padding: 0; }
  .steps li a { color: inherit; text-decoration: none; }
  .steps li a:hover { text-decoration: underline; }
  .steps li { font-family: var(--mono); font-size: .72rem; letter-spacing: .1em; text-transform: uppercase;
              color: var(--faint); border: 1px solid var(--line); border-radius: 100px; padding: .25rem .7rem; }
  .steps li.on { background: var(--accent); border-color: var(--accent); color: var(--crust); font-weight: 650; }
  .steps li.done { border-color: var(--good); color: var(--good); }
  .req { width: 100%; border-collapse: collapse; font-size: .9rem; }
  .req td { padding: .5rem .6rem; border-bottom: 1px solid var(--line); vertical-align: top; }
  .req tr:last-child td { border-bottom: 0; }
  .req .state { width: 1%; white-space: nowrap; font-family: var(--mono); font-size: .78rem; }
  .yes { color: var(--good); } .no { color: var(--bad); } .warn { color: var(--warn); }
  .fix { color: var(--faint); font-size: .82rem; margin-top: .2rem; }
  pre.cfg { background: var(--crust); border: 1px solid var(--line); border-radius: var(--r);
            padding: .9rem; overflow: auto; font-size: .78rem; line-height: 1.5; max-height: 380px; }
</style>
<style>
  .installrun { margin-top: 1rem; padding: .9rem 1rem; border: 1px solid var(--line);
                border-radius: 10px; background: var(--panel); }
  .installrun__steps { list-style: none; margin: 0; padding: 0; font-size: .9rem; }
  .installrun__steps li { padding: .18rem 0; color: var(--dim); }
  .installrun__steps li::before { content: '\00b7  '; }
  .installrun__steps li.is-now  { color: var(--text); }
  .installrun__steps li.is-now::before  { content: '\2192  '; }
  .installrun__steps li.is-done { color: var(--ok, #a6e3a1); }
  .installrun__steps li.is-done::before { content: '\2713  '; }
</style>
</head>
<body>
<main class="wiz">
  <div style="display:flex;align-items:center;gap:.55rem;margin-bottom:.35rem">
    <span style="display:flex;gap:2px">
      <i style="width:4px;height:20px;border-radius:1px;background:var(--bad)"></i>
      <i style="width:4px;height:20px;border-radius:1px;background:var(--good)"></i>
      <i style="width:4px;height:20px;border-radius:1px;background:#89b4fa"></i>
    </span>
    <strong style="letter-spacing:-.03em">RetroVault installer</strong>
  </div>

  <ul class="steps">
    <?php foreach (['Requirements', 'Connection', 'Deployment', 'Settings', 'Administrator', 'Review', 'Install'] as $i => $label): ?>
      <?php $n = $i + 1; $cls = $step === $n ? 'on' : ($step > $n ? 'done' : ''); ?>
      <li class="<?= $cls ?>">
        <?php if (step_reachable($n) && $n !== $step): ?>
          <a href="?step=<?= $n ?>"><?= $n ?>. <?= h($label) ?></a>
        <?php else: ?>
          <?= $n ?>. <?= h($label) ?>
        <?php endif; ?>
      </li>
    <?php endforeach; ?>
  </ul>
<?php
}

function foot(): void
{
    echo '</main></body></html>';
}

function flash_error(string $msg): void
{
    echo '<div class="flash flash--error" style="margin-bottom:1rem">' . h($msg) . '</div>';
}

function flash_ok(string $msg): void
{
    echo '<div class="flash flash--ok" style="margin-bottom:1rem">' . h($msg) . '</div>';
}


// ============================================================================
// The answer file
//
// One definition, used by both installers: this file writes it at the end of a
// wizard run, reads it at the start of one, and bin/install.php installs from it
// without asking anything.
//
// INI rather than PHP. The command line installer alone could have read a PHP
// file - it already runs whatever is in the checkout - but the wizard accepts
// one by upload, and `require` on an uploaded file is remote code execution
// wearing a hat. parse_ini_string() executes nothing, takes comments, and is
// what a sysadmin expects a preseed file to look like anyway.
//
// Credentials are never written. They come out as the placeholders below, and
// an answer file still carrying one is refused rather than installed with a
// database user literally called change-database-user-here.
// ============================================================================

/** What an answer file may say, and what it means when it says nothing. */
function answers_defaults(): array
{
    return [
        'db'       => ['host' => '127.0.0.1', 'port' => 3306, 'name' => '',
                       'user' => '', 'pass' => ''],
        'admin'    => ['username' => '', 'password' => '', 'email' => '',
                       'display_name' => ''],
        'instance' => ['name' => 'RetroVault', 'tagline' => '', 'url' => '',
                       'currency' => 'SEK', 'timezone' => 'Europe/Stockholm',
                       'trusted_proxies' => ''],
        'install'  => ['deploy' => 'install', 'erase_uploads' => false,
                       'templates' => 'remote', 'examples' => false],
    ];
}

/**
 * The fields that are never written down, and what stands in for them.
 *
 * Both usernames as well as both passwords. A file that names the database
 * account and the administrator is a file that has to be handled carefully; one
 * where every credential is a blank is one that can be committed, templated and
 * passed around, which is the point of having it.
 */
function answers_placeholders(): array
{
    return [
        'db.user'        => 'change-database-user-here',
        'db.pass'        => 'change-database-password-here',
        'admin.username' => 'change-admin-username-here',
        'admin.password' => 'change-admin-password-here',
    ];
}

/**
 * An answer file, from a set of answers.
 *
 * Written with the comments, because the person opening it is about to fill in
 * four blanks and choose between three words for `deploy`, and a bare key with
 * no explanation is how the wrong one gets chosen.
 */
function answers_export(array $v): string
{
    $ph = answers_placeholders();
    $q  = function ($value): string {
        $value = (string) $value;
        // Quoted when it could be read as something other than a string: an
        // address with a semicolon in it, anything with a comma, anything empty.
        return preg_match('/^[A-Za-z0-9._\/:-]*$/', $value) === 1
            ? $value
            : '"' . str_replace('"', '\"', $value) . '"';
    };
    $bool = fn($b) => $b ? '1' : '0';
    $at   = date('j M Y, H:i');

    $lines = [];
    $lines[] = '; RetroVault install answers, written ' . $at . '.';
    $lines[] = ';';
    $lines[] = '; Fill in the four blanks below and this installs without asking anything:';
    $lines[] = ';';
    $lines[] = ';     php bin/install.php --answers this-file.ini --dry-run';
    $lines[] = ';     php bin/install.php --answers this-file.ini';
    $lines[] = ';';
    $lines[] = '; The web installer takes it too, on its first page.';
    $lines[] = ';';
    $lines[] = '; No password or username was saved. Replace every change-...-here below, or';
    $lines[] = '; leave them and set RETROVAULT_DB_PASS and RETROVAULT_ADMIN_PASS in the';
    $lines[] = '; environment instead, which keeps the secrets out of the file for good.';
    $lines[] = '';
    $lines[] = '[db]';
    $lines[] = 'host = ' . $q($v['db']['host'] ?? '127.0.0.1');
    $lines[] = 'port = ' . (int) ($v['db']['port'] ?? 3306);
    $lines[] = 'name = ' . $q($v['db']['name'] ?? '');
    $lines[] = 'user = ' . $ph['db.user'];
    $lines[] = 'pass = ' . $ph['db.pass'];
    $lines[] = '';
    $lines[] = '[admin]';
    $lines[] = 'username = ' . $ph['admin.username'];
    $lines[] = 'password = ' . $ph['admin.password'];
    $lines[] = '; Not a secret, and needed for password resets and mail.';
    $lines[] = 'email = ' . $q($v['admin']['email'] ?? '');
    $lines[] = 'display_name = ' . $q($v['admin']['display_name'] ?? '');
    $lines[] = '';
    $lines[] = '[instance]';
    $lines[] = 'name = ' . $q($v['instance']['name'] ?? 'RetroVault');
    $lines[] = 'tagline = ' . $q($v['instance']['tagline'] ?? '');
    $lines[] = '; The address clients reach this by. Mail and notifications build';
    $lines[] = '; links from it; without it they point nowhere.';
    $lines[] = 'url = ' . $q($v['instance']['url'] ?? '');
    $lines[] = 'currency = ' . $q($v['instance']['currency'] ?? 'SEK');
    $lines[] = 'timezone = ' . $q($v['instance']['timezone'] ?? 'Europe/Stockholm');
    $lines[] = '; Behind a reverse proxy, whose forwarded headers to believe.';
    $lines[] = 'trusted_proxies = ' . $q($v['instance']['trusted_proxies'] ?? '');
    $lines[] = '';
    $lines[] = '[install]';
    $lines[] = '; install  build the structure in an empty database';
    $lines[] = '; erase    drop what is there first - destroys the collection';
    $lines[] = '; keep     leave the database alone, write the configuration only';
    $lines[] = 'deploy = ' . $q($v['install']['deploy'] ?? 'install');
    $lines[] = '; With erase, whether the photographs on disk go too.';
    $lines[] = 'erase_uploads = ' . $bool($v['install']['erase_uploads'] ?? false);
    $lines[] = '; remote   fetch the published starter data';
    $lines[] = '; shipped  use the copies in this checkout';
    $lines[] = '; none     start with an empty filing tree';
    $lines[] = 'templates = ' . $q($v['install']['templates'] ?? 'remote');
    $lines[] = '; A handful of catalogue entries to look at.';
    $lines[] = 'examples = ' . $bool($v['install']['examples'] ?? false);
    $lines[] = '';

    return implode("\n", $lines);
}

/**
 * Reads one. Returns [answers, problems].
 *
 * Problems rather than exceptions, because both callers want the whole list: a
 * provisioning run that fails, is corrected and fails again on the next line is
 * three round trips where one would do.
 */
function answers_parse(string $ini): array
{
    $problems = [];
    $parsed = @parse_ini_string($ini, true, INI_SCANNER_TYPED);
    if (!is_array($parsed)) {
        return [answers_defaults(), ['That is not an answer file - it could not be read as INI.']];
    }

    $out = answers_defaults();
    foreach ($parsed as $section => $values) {
        if (!is_array($values)) {
            $problems[] = 'Line outside any section: ' . (string) $section;
            continue;
        }
        if (!array_key_exists($section, $out)) {
            $problems[] = 'Unknown section [' . (string) $section . '].';
            continue;
        }
        foreach ($values as $key => $value) {
            if (!array_key_exists($key, $out[$section])) {
                $problems[] = 'Unknown setting ' . (string) $section . '.' . (string) $key . '.';
                continue;
            }
            $out[$section][$key] = $value;
        }
    }

    // The two passwords from the environment, if it has them, so the file can be
    // templated and hold nothing secret. The environment wins because it is the
    // more specific of the two: a file is written once, an environment is set
    // per run.
    foreach ([['RETROVAULT_DB_PASS', 'db', 'pass'],
              ['RETROVAULT_ADMIN_PASS', 'admin', 'password']] as [$var, $group, $field]) {
        $fromEnv = getenv($var);
        if ($fromEnv !== false && $fromEnv !== '') {
            $out[$group][$field] = $fromEnv;
        }
    }

    return [$out, $problems];
}

/**
 * Everything wrong with a set of answers, at once.
 *
 * `$needAdmin` is false when the database is being left alone, because there is
 * presumably an administrator in it already.
 */
function answers_check(array $a, bool $needAdmin = true): array
{
    $bad = [];

    // Placeholders first. Installing with a database user called
    // change-database-user-here fails later and less clearly.
    foreach (answers_placeholders() as $path => $placeholder) {
        [$section, $key] = explode('.', $path);
        if ((string) ($a[$section][$key] ?? '') === $placeholder) {
            $bad[] = $path . ' still says ' . $placeholder . '.';
        }
    }

    foreach (['name', 'user'] as $field) {
        if (trim((string) $a['db'][$field]) === '') {
            $bad[] = 'db.' . $field . ' is required.';
        }
    }
    if (!in_array($a['install']['deploy'], ['install', 'erase', 'keep'], true)) {
        $bad[] = 'install.deploy must be install, erase or keep.';
    }
    if (!in_array($a['install']['templates'], ['remote', 'shipped', 'none'], true)) {
        $bad[] = 'install.templates must be remote, shipped or none.';
    }

    if ($needAdmin && $a['install']['deploy'] !== 'keep') {
        if (!preg_match('/^[a-zA-Z0-9._-]{3,60}$/', (string) $a['admin']['username'])) {
            $bad[] = 'admin.username must be 3-60 characters: letters, digits, dot, dash or underscore.';
        }
        // Checked here rather than left to the database, because a ten-character
        // minimum discovered after the schema has loaded means starting again.
        if (mb_strlen((string) $a['admin']['password']) < 10) {
            $bad[] = 'admin.password must be at least 10 characters.';
        }
        if (!filter_var((string) $a['admin']['email'], FILTER_VALIDATE_EMAIL)) {
            $bad[] = 'admin.email must be an address.';
        }
    }

    $url = trim((string) $a['instance']['url']);
    if ($url !== '' && !filter_var($url, FILTER_VALIDATE_URL)) {
        $bad[] = 'instance.url does not look like an address.';
    }
    if (!in_array((string) $a['instance']['timezone'], timezone_identifiers_list(), true)) {
        $bad[] = 'instance.timezone is not a timezone PHP knows.';
    }
    return $bad;
}

/** The answers this wizard run collected, in the answer file's shape. */
function answers_from_session(): array
{
    return [
        'db' => [
            'host' => (string) recall('db_host', '127.0.0.1'),
            'port' => (int) recall('db_port', 3306),
            'name' => (string) recall('db_name', ''),
            // Never read back into the file, but the shape wants them.
            'user' => '', 'pass' => '',
        ],
        'admin' => [
            'username' => '', 'password' => '',
            'email'        => (string) recall('admin_email', ''),
            'display_name' => (string) recall('admin_display_name', ''),
        ],
        'instance' => [
            'name'            => (string) recall('app_name', 'RetroVault'),
            'tagline'         => (string) recall('app_tagline', ''),
            'url'             => (string) recall('base_url', ''),
            'currency'        => (string) recall('currency', 'SEK'),
            'timezone'        => (string) recall('timezone', 'Europe/Stockholm'),
            'trusted_proxies' => (string) recall('trusted_proxies', ''),
        ],
        'install' => [
            'deploy'        => (string) recall('deploy_action', 'install'),
            'erase_uploads' => (bool) recall('erase_uploads', false),
            'templates'     => (string) recall('templates', 'remote'),
            'examples'      => (string) recall('examples', '0') === '1',
        ],
    ];
}

// Everything above is a function. Everything below is the wizard, and the
// command line wants none of it.
if (PHP_SAPI === 'cli') {
    return;
}

// ============================================================================
// Download the generated configuration
//
// Offered whenever src/ is not writable, and again at the end so the file can
// be kept somewhere safe. Requires answers in the session, so a fresh browser
// cannot pull someone else's database password out of it.
// ============================================================================

// The answers, so the next machine does not need the wizard at all.
//
// Offered at the end, where somebody has just answered all of it once and is in
// the best position to know they will be answering it again. Credentials are
// left as placeholders by answers_export(); nothing secret is in the session by
// then anyway except the database password, and writing it into a file people
// download is how it ends up in a ticket.
if (($_GET['download'] ?? '') === 'answers') {
    if (recall('db_name') === null) {
        http_response_code(404);
        exit('Nothing to write. Work through the installer first.');
    }
    $body = answers_export(answers_from_session());
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="retrovault-install.ini"');
    header('Content-Length: ' . strlen($body));
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');
    echo $body;
    exit;
}

if (($_GET['download'] ?? '') === 'config') {
    if (recall('db_name') === null || recall('db_host') === null) {
        http_response_code(404);
        exit('Nothing to download. Work through the installer first.');
    }
    $body = config_from_session();
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="config.local.php"');
    header('Content-Length: ' . strlen($body));
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');
    echo $body;
    exit;
}

// ============================================================================
// Refuse to run when a configuration already exists
// ============================================================================

if (config_exists() && !wizard_is_active()) {
    head('Already configured');
    ?>
    <h1>RetroVault is already configured</h1>
    <p class="lede">
      <span class="mono"><?= h(pretty_path(CONFIG_FILE)) ?></span> exists, so the installer has
      stopped. It only runs on a system that has not been set up yet.
    </p>

    <div class="panel" style="border-left:4px solid var(--bad)">
      <h2 class="panel__title">Remove this file</h2>
      <p style="margin-top:0">
        An installer sitting in a document root is a liability even when it
        declines to do anything.
      </p>
      <pre class="cfg">rm <?= h(__FILE__) ?></pre>
    </div>

    <div class="panel" style="margin-top:1rem">
      <h2 class="panel__title">If you really do need to run it again</h2>
      <p style="margin-top:0;font-size:.9rem;color:var(--dim)">
        Move the configuration aside and reload this page. Keeping a copy means
        you can put it straight back if you change your mind.
      </p>
      <pre class="cfg">mv <?= h(pretty_path(CONFIG_FILE)) ?> <?= h(pretty_path(CONFIG_FILE)) ?>.bak</pre>
      <p style="font-size:.9rem;color:var(--dim)">
        The wizard will then notice the existing database and offer to keep it —
        which is what you want when moving to a new server — or to erase it.
        Nothing is destroyed without a typed confirmation.
      </p>
    </div>

    <div class="panel" style="margin-top:1rem">
      <h2 class="panel__title">Updating rather than reinstalling</h2>
      <p style="margin-top:0;font-size:.9rem;color:var(--dim)">
        If you have just copied new files over an existing install, you want the
        updater, not this. It applies pending migrations and checks the database
        structure without touching your settings.
      </p>
      <pre class="cfg">php bin/migrate.php status</pre>
      <p><a class="btn" href="update.php">Open the updater</a></p>
    </div>

    <p style="margin-top:1.5rem"><a class="btn btn--accent" href="./">Go to RetroVault</a></p>
    <?php
    foot();
    exit;
}

// Past the gate with no config: this session is doing a legitimate install.
if (!config_exists()) {
    remember(['wizard_active' => true]);
}

check_token();

// ============================================================================
// Steps
// ============================================================================

$step = step();

// The one-way door, enforced rather than merely unlinked.
//
// step_reachable() decides what the stepper offers, but a URL typed by hand does not
// consult it. Once the install has started there is nothing to go back to, so every
// other step redirects to it.
if (($step !== 7)
    && ((bool) recall('installing') || ((bool) recall('applied') && config_exists()))) {
    header('Location: ?step=7');
    exit;
}

// An answer file, offered on the first page.
//
// Presets the whole wizard from a file a previous run wrote, so a second machine
// is one page and a button rather than seven pages of the same answers. The
// credentials are the one thing the file does not carry, so those steps are
// still shown and still have to be filled in - which is the right shape: the
// tedious part is preset, the secret part is asked for.
//
// Parsed, never executed. parse_ini_string() runs nothing, which is the whole
// reason the format is INI and not PHP - `require` on an uploaded file would
// hand anybody who can reach an uninstalled instance a shell.
$presetProblems = [];
$presetOk = false;
if ($step === 1 && $_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['preset'])) {
    check_token();

    $body = '';
    if (isset($_FILES['answers']) && is_uploaded_file((string) ($_FILES['answers']['tmp_name'] ?? ''))) {
        // Capped: this is a short text file, and an installer is reachable
        // before anything is configured.
        if ((int) $_FILES['answers']['size'] > 64 * 1024) {
            $presetProblems[] = 'That file is far too large to be an answer file.';
        } else {
            $body = (string) file_get_contents((string) $_FILES['answers']['tmp_name']);
        }
    } elseif (trim((string) ($_POST['answers_text'] ?? '')) !== '') {
        $body = (string) $_POST['answers_text'];
    } else {
        $presetProblems[] = 'Choose a file, or paste one in.';
    }

    if ($body !== '' && $presetProblems === []) {
        [$answers, $presetProblems] = answers_parse($body);
        if ($presetProblems === []) {
            remember([
                'db_host'         => (string) $answers['db']['host'],
                'db_port'         => (string) (int) $answers['db']['port'],
                'db_name'         => (string) $answers['db']['name'],
                'app_name'        => (string) $answers['instance']['name'],
                'app_tagline'     => (string) $answers['instance']['tagline'],
                'base_url'        => (string) $answers['instance']['url'],
                'currency'        => (string) $answers['instance']['currency'],
                'timezone'        => (string) $answers['instance']['timezone'],
                'trusted_proxies' => (string) $answers['instance']['trusted_proxies'],
                'deploy_action'   => (string) $answers['install']['deploy'],
                'erase_uploads'   => (bool) $answers['install']['erase_uploads'],
                'templates'       => (string) $answers['install']['templates'],
                'examples'        => $answers['install']['examples'] ? '1' : '0',
                'admin_email'        => (string) $answers['admin']['email'],
                'admin_display_name' => (string) $answers['admin']['display_name'],
            ]);
            // Credentials only if the file actually carried them - which it does
            // when the environment filled the placeholders in, and does not when
            // somebody downloaded it and has not edited it yet.
            $creds = [];
            $ph = answers_placeholders();
            if ((string) $answers['db']['user'] !== '' && $answers['db']['user'] !== $ph['db.user']) {
                $creds['db_user'] = (string) $answers['db']['user'];
            }
            if ((string) $answers['db']['pass'] !== '' && $answers['db']['pass'] !== $ph['db.pass']) {
                $creds['db_pass'] = (string) $answers['db']['pass'];
            }
            if ((string) $answers['admin']['username'] !== ''
                && $answers['admin']['username'] !== $ph['admin.username']) {
                $creds['admin_username'] = (string) $answers['admin']['username'];
            }
            if ($creds !== []) { remember($creds); }
            $presetOk = true;

            // Complete, so there is nothing left to ask.
            //
            // answers_check() passing means the file carried the database
            // account and the administrator as well as everything else - so the
            // remaining five pages would each be shown filled in for somebody to
            // press past. Skip them.
            $ready = answers_check($answers);
            if ($ready === []) {
                // Reachable, checked here rather than asserted. Setting
                // db_reached on the strength of a file saying so would send
                // somebody to the review page to be told at the last moment
                // that the database was never there.
                try {
                    pdo_connect((string) $answers['db']['host'], (int) $answers['db']['port'],
                                (string) $answers['db']['name'], (string) $answers['db']['user'],
                                (string) $answers['db']['pass']);
                    $reached = true;
                } catch (Throwable $e) {
                    $reached = false;
                    $presetOk = false;
                    $presetProblems[] = 'Could not connect to that database: ' . $e->getMessage();
                }

                if ($reached) {
                    remember([
                        'db_user'      => (string) $answers['db']['user'],
                        'db_pass'      => (string) $answers['db']['pass'],
                        'db_reached'   => true,
                        'settings_set' => true,
                        'admin_username' => (string) $answers['admin']['username'],
                        // Hashed now, so the session never holds a password in
                        // plain text - the same thing step 5 does with the one
                        // it is typed into.
                        'admin_hash'   => password_hash((string) $answers['admin']['password'],
                                                        PASSWORD_DEFAULT),
                        'admin_set'    => true,
                    ]);

                    // Anything but a plain install stops at the review page.
                    //
                    // "erase" destroys a collection, and a browser is not the
                    // command line: there, somebody typed the command and meant
                    // it. Here a file was dragged onto a page, and a drag is not
                    // consent to drop every table. So the answers are loaded,
                    // the summary is shown, and the button is theirs to press.
                    if ((string) $answers['install']['deploy'] === 'install') {
                        $step = 7;
                        $_POST['apply'] = '1';
                    } else {
                        header('Location: ?step=7');
                        exit;
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------- 1. Checks
if ($step === 1) {
    $checks = requirements();
    $blocking = array_filter($checks, fn($c) => $c['fatal'] && !$c['ok']);

    // The fourth value is why a check failed. Nothing shows it any more - the
    // line says the check failed and stops there - so it is not unpacked, rather
    // than sitting unused and inviting somebody to wonder what it was for.
    [$updState, $updLatest, $updUrl] = installer_update_state();

    head('Requirements');
    ?>
    <h1>Before we start</h1>

    <?php if ($updState === 'behind'): ?>
      <?php
      // One sentence, the same one the settings screen gives.
      //
      // It used to quote what GitHub said and then explain that it did not
      // matter - a paragraph about somebody else's API, on the first page of an
      // installer, saying at length that it was not worth reading. Whether this
      // copy is current is worth a line; why the check failed is not.
      ?>
      <div class="note note--warn">
        Installing <?= h(installer_version()) ?> — outdated,
        <?php if ($updUrl): ?>
          <a href="<?= h($updUrl) ?>" rel="noopener noreferrer external">version
            <?= h($updLatest) ?> available</a>.
        <?php else: ?>
          version <?= h($updLatest) ?> available.
        <?php endif; ?>
      </div>
    <?php elseif ($updState === 'unknown'): ?>
      <div class="note">
        Installing <?= h(installer_version() ?: 'this copy') ?> — could not check
        for a newer version.
      </div>
    <?php else: ?>
      <div class="note note--ok">
        Installing <?= h(installer_version()) ?> — up to date.
      </div>
    <?php endif; ?>
      <?php
      // A file, dropped. Nothing else.
      //
      // No AJAX: the form posts, the server validates with the same code the
      // command line installer uses, and the page comes back in one of three
      // states. A JSON endpoint would have been a second way to reach one
      // answer, and the reload costs nothing on a page that is already a form.
      //
      // The button below is for a browser with no JavaScript, and is hidden by
      // the script the moment there is any - so dropping or choosing a file
      // submits on its own, which is what makes this a drop zone rather than a
      // form with a fancy border.
      ?>
      <form method="post" action="?step=1" enctype="multipart/form-data"
            id="rv-preset" style="margin:1.2rem 0">
        <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
        <input type="hidden" name="preset" value="1">

        <div id="rv-drop" style="
             border:2px dashed <?= $presetOk ? 'var(--ok,#3ba55d)' : ($presetProblems ? 'var(--bad,#e05260)' : 'var(--line,#3a3a4a)') ?>;
             border-radius:10px;padding:1.4rem;text-align:center;cursor:pointer;
             transition:border-color .15s, background .15s">
          <strong style="font-size:.95rem">No-prompt installation configuration</strong>

          <?php if ($presetOk): ?>
            <div style="margin-top:.5rem;color:var(--ok,#3ba55d);font-size:.9rem">
              Accepted — the pages below are filled in.
            </div>
          <?php elseif ($presetProblems): ?>
            <?php
            // A fumbled second drop does not throw away a file that was already
            // accepted, so the line has to say which of the two happened.
            ?>
            <div style="margin-top:.5rem;color:var(--bad,#e05260);font-size:.9rem">
              <?= recall('db_name') !== null
                  ? 'Not usable — the earlier one still stands.'
                  : 'Not usable. Carry on below, or drop another.' ?>
            </div>
            <ul style="margin:.5rem 0 0;padding:0;list-style:none;
                       color:var(--dim);font-size:.8rem;line-height:1.5">
              <?php foreach (array_slice($presetProblems, 0, 4) as $problem): ?>
                <li><?= h($problem) ?></li>
              <?php endforeach; ?>
            </ul>
          <?php endif; ?>

          <input type="file" name="answers" id="rv-file" accept=".ini,text/plain"
                 style="display:block;margin:.7rem auto 0">
          <noscript><button class="btn" type="submit" style="margin-top:.6rem">Use it</button></noscript>
        </div>
      </form>

      <script>
      (function () {
        var form = document.getElementById('rv-preset');
        var zone = document.getElementById('rv-drop');
        var file = document.getElementById('rv-file');
        if (!form || !zone || !file) { return; }

        // The input is only visible without JavaScript. With it, the whole box
        // is the target.
        file.style.display = 'none';

        var idle = zone.style.borderColor;
        function lit(on) { zone.style.borderColor = on ? '#7aa2f7' : idle; }

        zone.addEventListener('click', function () { file.click(); });
        file.addEventListener('change', function () {
          if (file.files.length) { form.submit(); }
        });

        ['dragenter', 'dragover'].forEach(function (e) {
          zone.addEventListener(e, function (ev) { ev.preventDefault(); lit(true); });
        });
        ['dragleave', 'dragend'].forEach(function (e) {
          zone.addEventListener(e, function () { lit(false); });
        });
        zone.addEventListener('drop', function (ev) {
          ev.preventDefault();
          lit(false);
          if (!ev.dataTransfer || !ev.dataTransfer.files.length) { return; }
          // Assigned to the input rather than sent by fetch, so the request is
          // the same multipart post the button makes and the server has one
          // path to handle.
          file.files = ev.dataTransfer.files;
          form.submit();
        });

        // Dropping anywhere else should not make the browser navigate to the
        // file, which is what it does by default and looks like a crash.
        ['dragover', 'drop'].forEach(function (e) {
          document.addEventListener(e, function (ev) {
            if (!zone.contains(ev.target)) { ev.preventDefault(); }
          });
        });
      })();
      </script>

    <div class="panel">
      <table class="req">
        <?php foreach ($checks as $c): ?>
        <tr>
          <td class="state">
            <?php if ($c['ok']): ?><span class="yes">PASS</span>
            <?php elseif ($c['fatal']): ?><span class="no">FAIL</span>
            <?php else: ?><span class="warn">WARN</span><?php endif; ?>
          </td>
          <td>
            <strong><?= h($c['name']) ?></strong>
            <span class="mono" style="color:var(--faint);font-size:.78rem"> — <?= h($c['found']) ?></span>
            <?php if (!$c['ok']): ?><div class="fix"><?= h($c['fix']) ?></div><?php endif; ?>
          </td>
        </tr>
        <?php endforeach; ?>
      </table>
    </div>

    <?php if ($blocking): ?>
      <div class="flash flash--error" style="margin-top:1rem">
        Fix the failures above, restart Apache, then reload this page.
      </div>
      <p style="margin-top:1rem"><a class="btn" href="?step=1">Re-check</a></p>
    <?php else: ?>
      <form method="post" action="?step=2" style="margin-top:1.5rem">
        <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
        <button class="btn btn--accent" type="submit">Continue to the database</button>
      </form>

    <?php endif; ?>
    <?php
    foot();
    exit;
}

// -------------------------------------------------------------- 2. Connection
//
// This step proves one thing: that we can reach the database and that it
// exists. Nothing is created and nothing is destroyed here, which is what makes
// it safe to re-run while sorting out a hostname or a grant.
if ($step === 2) {
    $error   = null;
    $summary = [];
    $reached = false;

    $host = post('db_host', (string) recall('db_host', '127.0.0.1'));
    $port = post('db_port', (string) recall('db_port', '3306'));
    $name = post('db_name', (string) recall('db_name', 'retrovault'));
    $user = post('db_user', (string) recall('db_user', 'retrovault'));
    $pass = post('db_pass', (string) recall('db_pass', ''));

    // Only when the button was actually pressed. Arriving here from step 1 is
    // also a POST, and connecting on the way in means a failure is reported
    // before anyone has been given the chance to type anything.
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['test_connection'])) {
        try {
            $pdo = pdo_connect($host, (int) $port, $name, $user, $pass);
            $reached = true;

            $version = (string) $pdo->query('SELECT VERSION()')->fetchColumn();
            $charset = (string) $pdo->query('SELECT @@character_set_database')->fetchColumn();
            $summary[] = 'Connected to ' . $version;
            $summary[] = 'Database "' . $name . '" exists and is reachable';

            // Deliberately silent about what is already here. This step answers
            // one question - can we reach the database - and the next one is
            // where an existing collection is reported and a choice made about
            // it. Warning twice made the first one look like a problem with the
            // connection.

            if (stripos($charset, 'utf8mb4') === false) {
                $summary[] = 'WARNING: the charset is ' . $charset . ', not utf8mb4. Swedish and '
                           . 'Japanese titles will be mangled. Fix this before going any further.';
            } else {
                $summary[] = 'Character set is utf8mb4';
            }

            // Can this account actually create tables? Better to find out now
            // than halfway through loading the schema.
            try {
                $pdo->exec('CREATE TABLE IF NOT EXISTS _rv_permission_probe (id INT)');
                $pdo->exec('DROP TABLE IF EXISTS _rv_permission_probe');
                $summary[] = 'The account may create and drop tables';
            } catch (PDOException $e) {
                $summary[] = 'WARNING: this account cannot create tables. GRANT ALL ON `'
                           . $name . '`.* is what the next step needs.';
            }

            remember([
                'db_host' => $host, 'db_port' => $port, 'db_name' => $name,
                'db_user' => $user, 'db_pass' => $pass, 'db_reached' => true,
            ]);
        } catch (PDOException $e) {
            $error = $e->getMessage();
            remember(['db_reached' => false]);
        }
    }

    head('Connection');
    ?>
    <h1>Connect to the database</h1>
    <p class="lede">
      This step only checks that the server answers and the database is there.
      Nothing is created or changed, so you can re-run it as often as you like
      while sorting out a hostname or a grant.
    </p>

    <?php if ($error): ?><?php flash_error($error); ?><?php endif; ?>
    <?php foreach ($summary as $line): ?>
      <?php str_starts_with($line, 'WARNING') ? flash_error($line) : flash_ok($line); ?>
    <?php endforeach; ?>

    <form method="post" action="?step=2" class="panel">
      <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
      <div class="formgrid">
        <div class="field field--half">
          <label for="db_host">Host</label>
          <input id="db_host" name="db_host" type="text" required value="<?= h($host) ?>" placeholder="10.0.0.30">
          <span class="hint">The MariaDB server, which may not be this machine.</span>
        </div>
        <div class="field field--tiny">
          <label for="db_port">Port</label>
          <input id="db_port" name="db_port" type="number" required value="<?= h($port) ?>">
        </div>
        <div class="field field--third">
          <label for="db_name">Database</label>
          <input id="db_name" name="db_name" type="text" required value="<?= h($name) ?>">
          <span class="hint">It must already exist; the installer will not create it.</span>
        </div>
        <div class="field field--third">
          <label for="db_user">Username</label>
          <input id="db_user" name="db_user" type="text" required value="<?= h($user) ?>">
        </div>
        <div class="field field--third">
          <label for="db_pass">Password</label>
          <input id="db_pass" name="db_pass" type="password" value="<?= h($pass) ?>" autocomplete="off">
        </div>
      </div>
      <div class="formactions">
        <button class="btn btn--accent" type="submit" name="test_connection" value="1">Test the connection</button>
      </div>
    </form>

    <?php if (($reached || recall('db_reached')) && $error === null): ?>
      <form method="post" action="?step=3" style="margin-top:1.5rem">
        <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
        <button class="btn btn--accent" type="submit">Continue to deployment</button>
      </form>
    <?php endif; ?>
    <?php
    foot();
    exit;
}

// -------------------------------------------------------------- 3. Deployment
//
// Separate from connecting on purpose. This is the only step that writes to the
// database, so it is the only one where a mistake costs anything.
if ($step === 3) {
    if (!recall('db_reached')) { header('Location: ?step=2'); exit; }

    $error = null;
    // Which field the message belongs to, when it belongs to one.
    $errorField = null;
    $host = (string) recall('db_host'); $port = (string) recall('db_port');
    $name = (string) recall('db_name'); $user = (string) recall('db_user');
    $pass = (string) recall('db_pass');

    $pdo = null;
    try { $pdo = pdo_connect($host, (int) $port, $name, $user, $pass); }
    catch (PDOException $e) { $error = 'Lost the connection: ' . $e->getMessage(); }

    if ($pdo !== null && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $choice = post('deploy_action');
        $counts = existing_data_counts($pdo);

        if ($choice === 'erase' && has_real_data($counts)
            && strtoupper(trim(post('erase_confirm'))) !== 'ERASE') {
            $error      = trim(post('erase_confirm')) === ''
                ? 'Type ERASE in the confirmation box to choose a total reinstall.'
                : 'That is not ERASE. Type it exactly, in capitals.';
            // Marked on the box as well: a message at the top of the page is a
            // message beside the wrong thing, and this page has two panels.
            $errorField = 'erase_confirm';
        } elseif (in_array($choice, ['install', 'keep', 'erase'], true)) {
            // Recorded, not performed. Nothing touches the database until the
            // last step, so changing your mind here costs nothing.
            remember([
                'deploy_action' => $choice,
                // An erase is total: the tables and the photos together.
                'erase_uploads' => $choice === 'erase',
            ]);
            header('Location: ?step=4');
            exit;
        } else {
            $error = 'Choose what to do with this database.';
        }
    }

    $state = $pdo === null ? null : [
        'structure' => structure_present($pdo),
        'counts'    => existing_data_counts($pdo),
    ];
    $chosen = (string) recall('deploy_action', '');

    head('Deployment');
    ?>
    <h1>Deployment</h1>
    <p class="lede">
      Decide what should happen to this database. Nothing is carried out here —
      the last step does all of it at once, so you can come back and change this.
    </p>

    <?php if ($error): ?><?php flash_error($error); ?><?php endif; ?>

    <?php
    $hasCollection = $state !== null && has_real_data($state['counts']);
    $bits = [];
    if ($state !== null) {
        foreach ($state['counts'] as $label => $n) {
            if ($n > 0) { $bits[] = '<strong>' . (int) $n . '</strong> ' . h($label); }
        }
    }
    ?>

    <?php if ($state === null): ?>
      <p class="lede">The connection was lost. <a href="?step=2">Go back and check it.</a></p>

    <?php elseif (!$state['structure']): ?>
      <section class="panel" style="border-left:4px solid var(--good)">
        <h2 class="panel__title">The database is empty</h2>
        <p style="margin-top:0">Nothing of RetroVault's is here, so there is nothing to lose.</p>
        <form method="post" action="?step=3">
          <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
          <input type="hidden" name="deploy_action" value="install">
          <p style="font-size:.9rem;color:var(--dim)">
            This step builds the structure. Whether to fill it with starter data
            — and whether to take that from GitHub or the copies that shipped —
            is asked on the Settings step.
          </p>
          <button class="btn btn--accent" type="submit">Create the structure, and continue</button>
        </form>
      </section>

    <?php elseif (!$hasCollection): ?>
      <section class="panel" style="border-left:4px solid var(--good)">
        <h2 class="panel__title">The tables exist but hold no collection</h2>
        <p style="margin-top:0">
          <?= $bits === [] ? 'Nothing in them at all.' : implode(', ', $bits) . ' — starter data only.' ?>
          Nothing anybody would miss.
        </p>
        <form method="post" action="?step=3">
          <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
          <input type="hidden" name="deploy_action" value="erase">
          <button class="btn btn--accent" type="submit">Rebuild it, and continue</button>
        </form>
      </section>
      <section class="panel" style="margin-top:1rem">
        <h2 class="panel__title">Or leave it alone</h2>
        <form method="post" action="?step=3">
          <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
          <input type="hidden" name="deploy_action" value="keep">
          <button class="btn" type="submit">Keep it, and continue</button>
        </form>
      </section>

    <?php else: ?>
      <p class="lede">There is a collection here: <?= implode(', ', $bits) ?>. Two ways forward.</p>
      <div class="cols cols--2">
        <section class="panel" style="margin:0;border-left:4px solid var(--good)">
          <h2 class="panel__title">Preserve it<?= $chosen === 'keep' ? ' — chosen' : '' ?></h2>
          <p style="margin-top:0;font-size:.9rem;color:var(--dim)">
            Left exactly as it is; only the configuration file is written. What
            you want when moving to a new server.
          </p>
          <form method="post" action="?step=3">
            <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
            <input type="hidden" name="deploy_action" value="keep">
            <button class="btn btn--accent" type="submit">Keep it, and continue</button>
          </form>
        </section>
        <section class="panel" style="margin:0;border-left:4px solid var(--bad)">
          <h2 class="panel__title">Total reinstall<?= $chosen === 'erase' ? ' — chosen' : '' ?></h2>
          <p style="margin-top:0;font-size:.9rem;color:var(--dim)">
            Drops and rebuilds every RetroVault table, and deletes the uploaded
            photos. Other tables in this database are untouched.
            <strong>Not reversible.</strong> Back up first:
          </p>
          <pre class="cfg">./bin/backup.sh /srv/backups/retrovault</pre>
          <form method="post" action="?step=3">
            <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
            <input type="hidden" name="deploy_action" value="erase">
            <?php $eraseBad = ($errorField ?? '') === 'erase_confirm'; ?>
            <div class="field" style="max-width:20rem">
              <label for="erase_confirm">Type ERASE to choose this</label>
              <input id="erase_confirm" name="erase_confirm" type="text" autocomplete="off"
                     placeholder="ERASE" value="<?= h(post('erase_confirm', '')) ?>"
                     <?= $eraseBad ? 'aria-invalid="true" autofocus' : '' ?>>
              <?php if ($eraseBad): ?>
                <span class="hint" style="color:var(--bad)"><?= h($error) ?></span>
              <?php endif; ?>
            </div>
            <div style="margin-top:1rem">
              <button class="btn btn--danger" type="submit">Choose reinstall, and continue</button>
            </div>
          </form>
        </section>
      </div>
    <?php endif; ?>
    <?php foot(); exit;
}

// ------------------------------------------------------------- 4. Settings
if ($step === 4) {
    if (recall('deploy_action') === null) { header('Location: ?step=3'); exit; }

    $guessHost = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $guessProto = (
        ($_SERVER['HTTPS'] ?? '') === 'on'
        || (int) ($_SERVER['SERVER_PORT'] ?? 80) === 443
        || strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https'
    ) ? 'https' : 'http';
    $v = [
        'app_name'        => post('app_name', (string) recall('app_name', 'RetroVault')),
        'app_tagline'     => post('app_tagline', (string) recall('app_tagline', 'Retro software collection')),
        'currency'        => post('currency', (string) recall('currency', 'SEK')),
        'timezone'        => post('timezone', (string) recall('timezone', 'Europe/Stockholm')),
        'base_url'        => post('base_url', (string) recall('base_url', $guessProto . '://' . $guessHost)),
        'trusted_proxies' => post('trusted_proxies', (string) recall('trusted_proxies', '')),
        // Whether the catalogue starts with anything in it.
        'templates'       => post('templates', (string) recall('templates', 'remote')),
        // A checkbox: absent on a POST means unticked, which is different from absent
        // because the page has not been submitted yet.
        'examples'        => $_SERVER['REQUEST_METHOD'] === 'POST'
            ? (isset($_POST['examples']) ? '1' : '0')
            : (string) recall('examples', '0'),
    ];
    $error = null;

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!in_array($v['timezone'], timezone_identifiers_list(), true)) {
            $error = 'That is not a recognised timezone identifier.';
        } elseif (!in_array($v['templates'], ['remote', 'local', 'none'], true)) {
            $error = 'Choose what to do about the starter data.';
        } else {
            remember($v + ['settings_set' => true]);
            header('Location: ?step=5');
            exit;
        }
    }

    head('Settings');
    ?>
    <h1>Settings</h1>
    <p class="lede">
      These go into <span class="mono">src/config.local.php</span>, which is written
      at the last step along with everything else.
    </p>
    <?php if ($error): ?><?php flash_error($error); ?><?php endif; ?>
    <form method="post" action="?step=4" class="panel">
      <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
      <div class="formgrid">
        <div class="field field--half">
          <label for="app_name">Name</label>
          <input id="app_name" name="app_name" type="text" value="<?= h($v['app_name']) ?>">
        </div>
        <div class="field field--half">
          <label for="app_tagline">Tagline</label>
          <input id="app_tagline" name="app_tagline" type="text" value="<?= h($v['app_tagline']) ?>">
        </div>
        <div class="field field--tiny">
          <label for="currency">Currency</label>
          <input id="currency" name="currency" type="text" value="<?= h($v['currency']) ?>">
        </div>
        <div class="field field--third">
          <label for="timezone">Timezone</label>
          <input id="timezone" name="timezone" type="text" value="<?= h($v['timezone']) ?>">
          <span class="hint">A tz identifier, such as Europe/Stockholm.</span>
        </div>
        <div class="field field--half">
          <label for="base_url">Public address</label>
          <input id="base_url" name="base_url" type="text" value="<?= h($v['base_url']) ?>">
          <span class="hint">Used in emails and API responses.</span>
        </div>
        <div class="field field--half">
          <label for="trusted_proxies">Trusted proxies</label>
          <input id="trusted_proxies" name="trusted_proxies" type="text" value="<?= h($v['trusted_proxies']) ?>"
                 placeholder="172.16.1.1">
          <span class="hint">Comma separated.</span>
        </div>

        <div class="field" style="grid-column:1/-1">
          <span class="label">Starter data</span>
          <label class="checkline">
            <input type="radio" name="templates" value="remote"
                   <?= ($v['templates'] ?? 'remote') === 'remote' ? 'checked' : '' ?>>
            <?php
            // Named for what it actually brings. "Makers, studios and genres" were
            // the old words: makers and studios became one companies table, and
            // genres became the category tree.
            ?>
            Fetch machines, companies and category trees from GitHub
          </label>
          <label class="checkline">
            <input type="radio" name="templates" value="local"
                   <?= ($v['templates'] ?? '') === 'local' ? 'checked' : '' ?>>
            Use the copies that shipped with this install
          </label>
          <label class="checkline">
            <input type="radio" name="templates" value="none"
                   <?= ($v['templates'] ?? '') === 'none' ? 'checked' : '' ?>>
            None &mdash; start empty
          </label>
        </div>

        <?php
        // Examples are a separate question.
        //
        // They were bundled with the reference data, so anyone who wanted sixty-three
        // platforms also got six invented entries and a second library they had not
        // asked for - and the only way to decline was to decline the platforms too.
        // Reference data is scaffolding; examples are somebody else's collection.
        ?>
        <div class="field" style="grid-column:1/-1">
          <span class="label">Example entries</span>
          <label class="checkline">
            <input type="checkbox" name="examples" value="1"
                   <?= ($v['examples'] ?? '0') === '1' ? 'checked' : '' ?>>
            Add a few example entries and a shared example library
          </label>
        </div>
      </div>
      <div class="formactions">
        <button class="btn btn--accent" type="submit">Continue</button>
      </div>
    </form>
    <?php foot(); exit;
}

// -------------------------------------------------------- 5. Administrator
if ($step === 5) {
    if (!recall('settings_set')) { header('Location: ?step=4'); exit; }

    $error = null;
    $username = post('username', (string) recall('admin_username', ''));
    $email    = post('email', (string) recall('admin_email', ''));

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $username = trim((string) ($_POST['username'] ?? ''));
        $email    = trim((string) ($_POST['email'] ?? ''));
        $password = (string) ($_POST['password'] ?? '');
        $confirm  = (string) ($_POST['password_confirm'] ?? '');

        if (!preg_match('/^[A-Za-z0-9._-]{3,64}$/', $username)) {
            $error = 'Username can use letters, numbers, dot, dash and underscore, 3 to 64 characters.';
        } elseif (strlen($password) < 10) {
            $error = 'Use a password of at least 10 characters.';
        } elseif ($password !== $confirm) {
            $error = 'The two passwords do not match.';
        } elseif ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $error = 'That does not look like an email address.';
        } else {
            // Hashed here rather than at the end, so the session never holds a
            // password in plain text even briefly.
            remember([
                'admin_username' => $username,
                'admin_email'    => $email,
                'admin_hash'     => password_hash($password, PASSWORD_DEFAULT),
                'admin_set'      => true,
            ]);
            header('Location: ?step=6');
            exit;
        }
    }

    head('Administrator');
    ?>
    <h1>Administrator account</h1>
    <p class="lede">
      The first account. It gets the admin role, and a library of its own to put
      things in. Created at the last step with everything else.
    </p>
    <?php if ($error): ?><?php flash_error($error); ?><?php endif; ?>
    <form method="post" action="?step=5" class="panel">
      <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
      <div class="formgrid">
        <div class="field field--half">
          <label for="username">Username</label>
          <input id="username" name="username" type="text" required value="<?= h($username) ?>" autocomplete="username">
        </div>
        <div class="field field--half">
          <label for="email">Email</label>
          <input id="email" name="email" type="email" value="<?= h($email) ?>" placeholder="you@example.com">
          <span class="hint">Optional. You can sign in with it as well as the username.</span>
        </div>
        <div class="field field--half">
          <label for="password">Password</label>
          <input id="password" name="password" type="password" required minlength="10" autocomplete="new-password">
          <span class="hint">At least 10 characters.</span>
        </div>
        <div class="field field--half">
          <label for="password_confirm">Password again</label>
          <input id="password_confirm" name="password_confirm" type="password" required minlength="10" autocomplete="new-password">
        </div>
      </div>
      <div class="formactions">
        <button class="btn btn--accent" type="submit">Continue</button>
        <?php if (recall('admin_set')): ?>
          <span class="hint">Already entered. Submitting again replaces it.</span>
        <?php endif; ?>
      </div>
    </form>
    <?php foot(); exit;
}

// --------------------------------------------------------- 6. Review, 7. Install
//
// Two steps, not one.
//
// Review shows the plan and changes nothing; Install is its own phase and the only
// thing that touches the database. Splitting them is what makes the progress honest:
// the browser gets a real page for the work rather than a form that appears to hang,
// and "go back" stops being a question, because by the time you are on step 7 the
// tables are already going.
if (!recall('admin_set')) { header('Location: ?step=5'); exit; }

$plan     = plan();
// Verified against the disk, not remembered. A session can outlive a
// redeployment - the config file is gitignored, so a fresh clone has none -
// and trusting the flag alone renders a success page for an install that is
// no longer there.
$applied  = (bool) recall('applied') && config_exists();
$deleted  = false;
$error    = null;
$log      = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['selfdestruct'])) {
    // Only once there is a configuration to run from. Deleting the installer
    // while the application cannot start leaves no way back in except a shell.
    if (!config_exists()) {
        $error = 'There is no configuration file yet, so the installer is the only way '
               . 'to finish. It will not delete itself while that is true.';
    } else {
        $deleted = @unlink(__FILE__);
        if ($deleted) {
            unset($_SESSION['install']['wizard_active']);
        }
    }
}

$running = $_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['apply']) && !$applied;

if ($running) {
    // Marked before the first table is touched, so a reload or a back button lands on
    // step 7 rather than offering to start again.
    remember(['installing' => true]);

    // The page is sent now and filled in as the work happens, so the browser paints
    // something immediately instead of waiting for the whole install. Buffering is the
    // enemy of that: zlib, nginx and PHP's own buffers will each happily hold the lot
    // until the script ends.
    while (ob_get_level() > 0) { ob_end_flush(); }
    @ini_set('zlib.output_compression', '0');
    @ini_set('output_buffering', '0');
    @ini_set('implicit_flush', '1');
    ob_implicit_flush(true);
    header('X-Accel-Buffering: no');
    header('Content-Type: text/html; charset=utf-8');

    head('Installing');
    echo install_progress_shell();
    install_tick('start');

    try {
        $pdo = pdo_connect($plan['db']['host'], (int) $plan['db']['port'],
                           $plan['db']['name'], $plan['db']['user'], $plan['db']['pass']);

        install_tick('db');
        // 1. The database
        if ($plan['deploy'] === 'erase') {
            $before = existing_data_counts($pdo);
            $pdo->exec('DROP TABLE IF EXISTS schema_migrations');
            $dropErrors = drop_retrovault_tables($pdo);
            if ($dropErrors !== []) {
                throw new RuntimeException('Some tables could not be dropped: '
                    . implode(' | ', array_slice($dropErrors, 0, 3)));
            }
            $log[] = 'Erased: ' . implode(', ', array_map(
                fn($v) => counted((int) $v['n'], (string) $v['one'], (string) $v['many']),
                array_values($before)));
            if ($plan['uploads_too']) {
                $purge = purge_uploads();
                // How many photographs the database had, to compare with what was
                // on disk. The two lines used to be written independently, so
                // "Erased: 8 photos" and "No uploaded files to delete" could sit
                // one above the other and neither knew the other was there.
                // Keyed by the plural label, not the table name: existing_data_counts()
                // builds $counts['photos'], because the same array is what the
                // "Erased: …" line is written from. I read it as ['item_images'],
                // which is null, so the branch below could never fire - a
                // diagnostic that was itself undiagnosable.
                $photoRows = (int) ($before['photos']['n'] ?? 0);

                if (!empty($purge['missing'])) {
                    $log[] = sprintf('%s does not exist, so no uploaded file was touched '
                        . '— if photographs are being stored, they are somewhere else, '
                        . 'and uploads.dir in the configuration is what says where',
                        pretty_path(UPLOADS_DIR));
                } elseif (!empty($purge['unreadable'])) {
                    $log[] = sprintf('%s could not be read, so no uploaded file was '
                        . 'touched — check that the web user can list it',
                        pretty_path(UPLOADS_DIR));
                } elseif ($purge['seen'] === 0 && $photoRows > 0) {
                    // The interesting case, and the one that reads as a
                    // contradiction if nobody says anything: rows for
                    // photographs, and no files where this expects them.
                    $log[] = sprintf('%s recorded, but no files were found in %s — '
                        . 'they are either stored somewhere else or were already gone, '
                        . 'and nothing on disk has been deleted',
                        counted($photoRows, 'photograph was', 'photographs were'),
                        pretty_path(UPLOADS_DIR));
                } elseif ($purge['seen'] === 0) {
                    $log[] = 'No uploaded files to delete';
                } elseif ($purge['removed'] === $purge['seen']) {
                    $log[] = counted($purge['removed'], 'uploaded file deleted', 'uploaded files deleted');
                } else {
                    // Said plainly, because the erase has not finished and nothing
                    // else will mention it. The usual cause is the directory being
                    // owned by somebody other than the web user.
                    $log[] = sprintf('%d of %d uploaded files could not be deleted — check '
                        . 'who owns %s; the rows are gone and the files are still there',
                        $purge['seen'] - $purge['removed'], $purge['seen'],
                        pretty_path(UPLOADS_DIR));
                }
            }
        }

        if ($plan['deploy'] === 'install' || $plan['deploy'] === 'erase') {
            [$errs, $msgs] = run_sql_file($pdo, SCHEMA_FILE);
            if ($errs > 0) {
                throw new RuntimeException('The schema did not load: ' . implode(' | ', $msgs));
            }
            install_tick('schema');
            $log[] = 'Structure created';
            $log[] = counted(installer_baseline($pdo), 'migration recorded', 'migrations recorded');
            // Always: db/seed.sql is auth methods and platform classes, which
            // the software cannot run without. It stopped being starter data
            // when the two were split, and skipping it would leave an instance
            // nobody can sign in to - which is not what "start empty" means.
            run_sql_file($pdo, SEED_FILE);
            $log[] = 'Core records created';
        } else {
            $log[] = 'Existing collection left untouched';
        }

        // 2. The configuration file
        $content = config_php(config_values());
        if (@file_put_contents(CONFIG_FILE, $content) !== false) {
            @chmod(CONFIG_FILE, 0640);
            $log[] = 'Configuration written to ' . pretty_path(CONFIG_FILE);
            install_tick('config');
        } else {
            throw new RuntimeException('Could not write ' . CONFIG_FILE
                . '. Let the web server write it just once - chgrp www '
                . dirname(CONFIG_FILE) . ' && chmod 775 ' . dirname(CONFIG_FILE)
                . ' - then press Install again. Nothing else has been left half done.');
        }

        // 3. The administrator, and somewhere to put things
        $st = $pdo->prepare('SELECT COUNT(*) FROM users WHERE username = ?');
        $st->execute([$plan['admin']]);
        if ((int) $st->fetchColumn() > 0) {
            $log[] = 'An account called ' . $plan['admin'] . ' already existed and was left alone';
        } else {
            $hasAuth = table_exists($pdo, 'auth_methods');
            // Verified on creation: this is the person running the install,
            // and there is nobody else on the instance to vouch for them. If
            // they had to confirm an address before signing in, and the relay
            // they have not configured yet could not send it, the install would
            // finish with nobody able to log into it.
            $sql = $hasAuth
                ? 'INSERT INTO users (username, auth_method_id, password_hash, display_name, email, role, is_active, email_verified_at)
                   VALUES (?, 1, ?, ?, ?, \'admin\', 1, NOW())'
                : 'INSERT INTO users (username, password_hash, display_name, email, role, is_active, email_verified_at)
                   VALUES (?, ?, ?, ?, \'admin\', 1, NOW())';
            $ins = $pdo->prepare($sql);
            $ins->execute([$plan['admin'], (string) recall('admin_hash'), $plan['admin'],
                           $plan['email'] !== '' ? $plan['email'] : null]);
            $adminId = (int) $pdo->lastInsertId();

            // Starter data, if it was asked for. Deliberately after the account
            // exists: an install that fails here still leaves somebody able to
            // sign in and try again from the settings page, rather than a
            // half-built instance nobody can reach.
            $want = (string) ($plan['templates'] ?? 'remote');
            if ($want !== 'none') {
                try {
                    install_tick('starter', $want === 'remote' ? 'over the network' : 'from disk');

                    // Where it came from is said in the result, not announced
                    // before it. This wrote "Fetching starter data from GitHub"
                    // into a list headed "what was done" - a present participle
                    // among past-tense entries, describing a step that had not
                    // happened yet, immediately above the line reporting how it
                    // went. The progress ticker is what narrates; this list
                    // records.
                    $from = $want === 'remote' ? 'GitHub' : 'the copies that shipped';

                    if (!installer_boot_app()) {
                        throw new RuntimeException('the application could not be loaded');
                    }
                    [$summary, $errors] = template_sync($want === 'remote');
                    $log[] = sprintf('Starter data: %d rows added from %s',
                                     array_sum(array_column($summary, 'added')), $from);
                    foreach ($errors as $err) {
                        $log[] = 'Starter data: ' . $err;
                    }
                    // A network that is not there should not stop an install.
                    if ($want === 'remote' && $errors !== []) {
                        // Past tense, like everything else in this list.
                        $log[] = 'Fell back to the copies that shipped';
                        [$summary2] = template_sync(false);
                        // The same words as the line above, for the same thing:
                        // "from disk" and "from the copies that shipped" side by
                        // side reads as two different sources.
                        $log[] = sprintf('Starter data: %d rows added from the copies that shipped',
                                         array_sum(array_column($summary2, 'added')));
                    }
                } catch (Throwable $e) {
                    $log[] = 'Starter data could not be loaded from '
                        . (($plan['templates'] ?? 'remote') === 'remote' ? 'GitHub' : 'disk')
                        . ': ' . $e->getMessage()
                           . ' (Instance settings can retry it)';
                }
            } else {
                $log[] = 'Starter data skipped; the catalogue starts empty '
                       . '(the administrator still gets their own personal library)';
            }
            install_tick('admin');
        $log[] = 'Administrator ' . $plan['admin'] . ' created';

            $lib = $pdo->prepare(
                // No domain column: a library holds both software and hardware,
                // and what an entry is comes from where it sits in the tree.
                // is_personal marks the one shelf every account gets and
                // nobody can delete.
                "INSERT INTO libraries (name, slug, description, owner_id, kind, is_personal, is_default, sort_order)
                 SELECT 'My Private Library', 'my-private-library',
                        'Yours alone. It cannot be shared, which is what makes it the one place you always have.',
                        ?, 'private', 1, 1, 10 FROM DUAL
                  WHERE NOT EXISTS (SELECT 1 FROM libraries)");
            $lib->execute([$adminId]);
            $mem = $pdo->prepare("INSERT IGNORE INTO library_members (library_id, user_id, access)
                                  SELECT id, ?, 'owner' FROM libraries WHERE is_default = 1");
            $mem->execute([$adminId]);
            // Named, so the summary is not ambiguous about what got made.
            //
            // "First library created" reads like the installer made a decision; it did
            // not. Every account has exactly one personal shelf and this is the
            // administrator's - it exists whatever was chosen about starter data,
            // because an account with nowhere to put anything is not a working account.
            $log[] = 'Personal library created for the administrator';

            // Copy the starter data into it. The installer builds this library
            // with raw SQL rather than through ensure_first_library(), so the
            // seeding that function does never ran - which is why a freshly
            // installed instance had platforms in the templates and none in the
            // only library that existed.
            try {
                if (!installer_boot_app()) {
                    throw new RuntimeException('the application could not be loaded');
                }
                $libId = (int) $pdo->query('SELECT id FROM libraries WHERE is_default = 1 LIMIT 1')->fetchColumn();

                // Only if starter data was asked for.
                //
                // This ran whatever the answer on the settings step, so choosing "none"
                // still filled the library - from the templates db/seed-templates.sql
                // loads with the schema, which are there regardless. The choice gated
                // fetching the templates and not copying them, which is the half nobody
                // sees.
                if ($libId > 0 && $want !== 'none') {
                    // The sources that need no key, configured before the
                    // library is seeded so seeding can switch them on.
                    //
                    // A fresh install used to configure none at all, so a new
                    // catalogue could look up nothing until somebody went to the
                    // agents screen and added them one at a time. These are the
                    // ones that ask for nothing: no account, no key, no terms to
                    // agree to. IGDB and TheGamesDB are left out because they
                    // need credentials somebody has to go and get.
                    $sources = 0;
                    if (function_exists('metadata_provider_types')) {
                        foreach (metadata_provider_types() as $type => $def) {
                            if (!empty($def['needs_key'])) {
                                continue;
                            }
                            if ((int) scalar('SELECT COUNT(*) FROM metadata_providers WHERE type = ?',
                                             [$type]) > 0) {
                                continue;
                            }
                            insert_row('metadata_providers', [
                                'name'       => (string) ($def['label'] ?? $type),
                                'type'       => (string) $type,
                                'params'     => json_encode($def['params'] ?? []),
                                'priority'   => 100,
                                'is_enabled' => 1,
                            ]);
                            $sources++;
                        }
                    }
                    if ($sources > 0) {
                        $log[] = sprintf('Metadata sources configured: %d, the ones needing no key',
                                         $sources);
                    }

                    $copied = seed_library_hardware($libId);
                    $log[]  = sprintf('Starter data copied into the library: %d machines', $copied);

                    // What each machine runs, copied with the platforms. Reported
                    // because a summary that lists everything except the newest thing
                    // is how somebody concludes it did not happen.
                    $envs = (int) scalar(
                        'SELECT COUNT(*) FROM operating_systems WHERE library_id = ?', [$libId]
                    );
                    if ($envs > 0) {
                        $log[] = sprintf('Environments copied: %d', $envs);
                    }
                    // The trees too, which are now by far the biggest thing seeding
                    // makes - one per machine, sized to what that kind of machine has -
                    // and the summary said nothing about them at all.
                    $cats = (int) scalar(
                        'SELECT COUNT(*) FROM categories WHERE library_id = ?', [$libId]
                    );
                    if ($cats > 0) {
                        // What those branches say they hold, not just how many
                        // there are.
                        //
                        // A count of 3,672 says the copy ran. It does not say the
                        // tree is usable, and the thing that makes it usable -
                        // every branch declaring games, applications, machines or
                        // peripherals - is new enough to be worth showing rather
                        // than assuming. If a line here ever reads "0 games", the
                        // template data or the importer has stopped agreeing with
                        // the column, which is exactly the failure that would
                        // otherwise be found weeks later by a browser filter
                        // returning nothing.
                        $kinds = [];
                        foreach (all('SELECT role, COUNT(*) AS n FROM categories
                                       WHERE library_id = ? AND role <> "other"
                                       GROUP BY role ORDER BY n DESC', [$libId]) as $row) {
                            $kinds[] = (int) $row['n'] . ' ' . (string) $row['role']
                                     . ((int) $row['n'] === 1 ? '' : 's');
                        }
                        $log[] = sprintf(
                            'Category trees built: %d kinds across %d machines%s',
                            $cats,
                            (int) scalar(
                                'SELECT COUNT(*) FROM categories WHERE library_id = ? AND parent_id IS NULL',
                                [$libId]
                            ),
                            $kinds === [] ? '' : ' — ' . implode(', ', $kinds)
                        );
                    }

                    // Whether those sources were actually switched on anywhere.
                    //
                    // "Configured: 7" says they exist; it does not say the tree
                    // asks any of them, and those are different facts - the first
                    // was true on the run before this one, when nothing had been
                    // switched on at all and nothing said so.
                    $switched = (int) scalar(
                        'SELECT COUNT(DISTINCT ps.category_id) FROM provider_scopes ps
                           JOIN categories c ON c.id = ps.category_id
                          WHERE c.library_id = ? AND ps.enabled = 1', [$libId]);
                    if ($switched > 0) {
                        $log[] = sprintf(
                            'Metadata sources switched on for %d branches, inherited by the rest',
                            $switched);
                    }

                    // A couple of example entries, so the first page somebody
                    // sees is not empty. Only where they asked for starter data:
                    // "start empty" means empty.
                    // Asked for separately. Reference data is scaffolding you want on
                    // any instance; examples are somebody else's collection, and the
                    // only way to decline them used to be declining the platforms too.
                    if ($want !== 'none' && !empty($plan['examples'])) {
                        $ex = seed_library_examples($libId);
                        if ($ex > 0) {
                            $log[] = sprintf('%d example entries added, to edit or delete', $ex);
                        }

                        // And a second, shared one. A single library shows nothing
                        // about what a library is for; two, holding different
                        // machines, show that each has its own makers, platforms and
                        // models.
                        $sharedId = seed_shared_example_library($adminId);
                        if ($sharedId > 0) {
                            $log[] = sprintf(
                                'Shared example library created with %d entries of its own',
                                (int) scalar('SELECT COUNT(*) FROM items WHERE library_id = ?', [$sharedId])
                            );
                        }
                    }
                }
            } catch (Throwable $e) {
                $log[] = 'Could not copy the starter data into the library: ' . $e->getMessage()
                       . ' (Instance settings can retry it)';
            }
        }

        remember(['applied' => true, 'apply_log' => $log]);
        install_tick('done');
        $applied = true;
    } catch (Throwable $e) {
        $error = $e->getMessage();
    }
}

// The work is finished. From here the page is the result, and the running panel goes.
if ($running) {
    // Everything from here is the result. Hidden until the panel has finished, or the
    // summary appears underneath a list that still says "Finishing" - which is what it
    // did: the server was done, but the display had four stages left to show.
    echo '<div id="installresult" hidden>';
    remember(['installing' => false]);
}

if ($applied && $log === []) {
    $log = (array) recall('apply_log', []);
}

// Already sent when streaming: the page opened before the work started.
if (!$running) {
    head($applied ? 'Installed' : 'Ready to install');
}
?>

<?php if (!$applied): ?>
  <h1>Ready to install</h1>
  <p class="lede">
    Nothing has been changed yet. This is everything that will happen, in order.
    Any of it can still be altered by going back.
  </p>

  <?php if ($error): ?><?php flash_error($error); ?><?php endif; ?>

  <div class="panel">
    <h2 class="panel__title">What will happen</h2>
    <table class="table">
      <tbody>
        <tr>
          <td style="width:30%">Database</td>
          <td>
            <span class="mono"><?= h($plan['db']['user']) ?>@<?= h($plan['db']['host']) ?>:<?= h($plan['db']['port']) ?>/<?= h($plan['db']['name']) ?></span>
            <a class="hint" href="?step=2" style="margin-left:.5rem">change</a>
          </td>
        </tr>
        <tr>
          <td>Deployment</td>
          <td>
            <?php if ($plan['deploy'] === 'install'): ?>
              Create the structure
            <?php elseif ($plan['deploy'] === 'erase'): ?>
              <strong style="color:var(--bad)">Drop every RetroVault table, rebuild, and delete the uploaded photos</strong>
            <?php else: ?>
              Leave the existing collection exactly as it is
            <?php endif; ?>
            <a class="hint" href="?step=3" style="margin-left:.5rem">change</a>
          </td>
        </tr>
        <tr>
          <td>Configuration</td>
          <td>
            Write <span class="mono"><?= h(pretty_path(CONFIG_FILE)) ?></span>
            <a class="hint" href="?step=4" style="margin-left:.5rem">change</a>
          </td>
        </tr>
        <tr>
          <td>Administrator</td>
          <td>
            <span class="mono"><?= h($plan['admin']) ?></span><?= $plan['email'] !== '' ? ' &lt;' . h($plan['email']) . '&gt;' : '' ?>, with a first library
            <a class="hint" href="?step=5" style="margin-left:.5rem">change</a>
          </td>
        </tr>
      </tbody>
    </table>

    <form method="post" action="?step=7" style="margin-top:1rem"
          <?= $plan['deploy'] === 'erase' ? 'data-confirm="Erase the existing collection and install?"' : '' ?>>
      <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
      <?php
      // apply travels as a hidden field, not on the button.
      //
      // The submit handler disables the button to stop a second click, and a disabled
      // control is not serialised - so the value the installer keys on never arrived,
      // it re-rendered this same step, and the progress panel appeared and vanished.
      // The field does not care whether the button is disabled.
      ?>
      <input type="hidden" name="apply" value="1">
      <button class="btn btn--accent" type="submit">Install now</button>
      <?php
      // Offered here as well as at the end, because here is where somebody is
      // looking at the whole plan and deciding it is right - which is the moment
      // they are best placed to keep it for the next machine, and the last
      // moment before the answers stop being a plan and start being an instance.
      //
      // Streamed by ?download=answers straight from the session. Nothing is
      // written to disk: an installer that leaves a file full of answers in the
      // document root has undone the reason none of the credentials are in it.
      ?>
      <a class="btn" href="?download=answers" style="margin-left:.4rem">Download answers</a>
    </form>
    <?php
    // Something to look at while it works.
    //
    // The install is one POST that drops tables, rebuilds, fetches the starter data
    // over the network and copies it into a library - several seconds, during which
    // the page simply sat there and looked hung. This is honest about what it is: a
    // list of the steps with the current one marked, advancing on a timer rather than
    // reporting real progress, because a single request cannot report on itself. The
    // last line stays until the server answers.
    ?>
  </div>

<?php else: ?>
  <h1>Installed</h1>
  <p class="lede">RetroVault is ready.</p>

  <div class="panel">
    <h2 class="panel__title">What was done</h2>
    <ul style="margin:0;padding-left:1.1rem;color:var(--dim);font-size:.9rem;line-height:1.8">
      <?php foreach ($log as $line): ?><li><?= h($line) ?></li><?php endforeach; ?>
    </ul>
  </div>

  <div class="panel" style="margin-top:1rem;border-left:4px solid var(--bad)">
    <h2 class="panel__title">Remove the installer</h2>
    <?php if ($deleted): ?>
      <p style="margin-top:0;color:var(--good)">Gone.</p>
    <?php elseif (!file_exists(__FILE__)): ?>
      <p style="margin-top:0;color:var(--good)">Already gone.</p>
    <?php else: ?>
      <p style="margin-top:0">
        It refuses to run now that a configuration exists, but leaving it in a
        document root is still a liability.
      </p>
      <?php
      // Posts to step 7, not 6. This panel only ever appears after the install, and
      // step 6 now redirects here - so a form aimed at 6 was bounced before its
      // handler could run and the button silently did nothing.
      ?>
      <form method="post" action="?step=7" style="margin:.8rem 0">
        <input type="hidden" name="_csrf" value="<?= h(token()) ?>">
        <button class="btn btn--danger" type="submit" name="selfdestruct" value="1">Delete install.php now</button>
      </form>
      <p style="font-size:.85rem;color:var(--dim);margin-bottom:.4rem">Or from a shell:</p>
      <pre class="cfg">rm <?= h(__FILE__) ?></pre>
    <?php endif; ?>
  </div>

  <div class="panel" style="margin-top:1rem">
    <h2 class="panel__title">The next one</h2>
    <p style="color:var(--dim);font-size:.9rem;line-height:1.6;margin-top:0">
      Everything just answered, as a file the installer can read back — so the
      second machine, and the twentieth, need none of these pages.
      <strong>No username or password is written into it</strong>: those come out
      as <span class="mono">change-…-here</span> for somebody to fill in, or as
      <span class="mono">RETROVAULT_DB_PASS</span> and
      <span class="mono">RETROVAULT_ADMIN_PASS</span> in the environment, which
      keeps them out of the file for good.
    </p>
    <p style="margin-bottom:.4rem">
      <a class="btn" href="?download=answers">Download install answers</a>
    </p>
    <pre class="cfg">php bin/install.php --answers retrovault-install.ini --dry-run
php bin/install.php --answers retrovault-install.ini --quiet</pre>
    <p style="color:var(--dim);font-size:.85rem;margin-bottom:0">
      Or hand it to this page on a fresh machine, on the first step, and press
      through in one click instead of seven.
    </p>
  </div>

  <div class="panel" style="margin-top:1rem">
    <h2 class="panel__title">Worth doing next</h2>
    <ul style="margin:0;padding-left:1.1rem;color:var(--dim);font-size:.9rem;line-height:1.7">
      <li>Tighten the config file: <span class="mono">chmod 640 <?= h(pretty_path(CONFIG_FILE)) ?></span>, group-owned by the web server group.</li>
      <li>
        The library you are working in is chosen in the header. Add more, or
        invite people into one, from <strong>Library access</strong> in the
        account menu — Manage is for what goes <em>in</em> a library, not for the
        libraries themselves.
      </li>
      <li>For phones and desktop apps, issue a token under <strong>App access</strong>.</li>
      <li>Schedule <span class="mono">bin/backup.sh</span> — it dumps the database and tars the photos.</li>
      <li>If you use LDAP or Active Directory, see <span class="mono">docs/LDAP.md</span>.</li>
    </ul>
  </div>

  <p style="margin-top:1.5rem">
    <a class="btn btn--accent" href="./login">Sign in as <?= h($plan['admin']) ?></a>
  </p>
<?php endif; ?>
<?php
// Close the result wrapper and let the progress panel finish before showing it.
if ($running) {
    echo '</div><script>window.__rvDone&&__rvDone();</script>';
}

foot();
