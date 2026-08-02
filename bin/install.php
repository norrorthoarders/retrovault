#!/usr/bin/env php
<?php
declare(strict_types=1);

/**
 * RetroVault, installed from the command line.
 *
 * The wizard in public/install.php asks seven pages of questions and is the
 * right thing for one machine. It is the wrong thing for the twentieth, for a
 * container that has to come up unattended, and for anything where the answers
 * belong in a file somebody can review before it runs.
 *
 * So this reads the answers instead of asking them, and does the same work in
 * the same order using the same functions - it includes the wizard for its
 * helpers rather than keeping a second copy of pdo_connect() and config_php()
 * that would drift.
 *
 *   php bin/install.php --example > install.ini
 *   $EDITOR install.ini
 *   php bin/install.php --answers install.ini --dry-run
 *   php bin/install.php --answers install.ini
 *
 * Exit status is 0 only if the install finished. Anything else is a failure with
 * a reason on stderr, which is what a provisioning script needs and what a web
 * page cannot give it.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit("bin/install.php is for the command line.\n");
}

define('APP_ROOT', dirname(__DIR__));

// The wizard, for its helpers. It returns before running anything on the CLI.
require APP_ROOT . '/public/install.php';

// ---------------------------------------------------------------------------
// Saying things
// ---------------------------------------------------------------------------

$QUIET = false;

function say(string $line): void
{
    global $QUIET;
    if (!$QUIET) { fwrite(STDOUT, '  ' . $line . "\n"); }
}

function note(string $line): void
{
    global $QUIET;
    // --quiet used to silence say() and leave these, so a "silent" install still
    // wrote three lines to stdout. Silent means nothing on success and the
    // reason on stderr on failure, because that is what a provisioning run wants
    // in its output when everything worked.
    if (!$QUIET) { fwrite(STDOUT, "\n" . $line . "\n\n"); }
}

/**
 * Stop, with a reason.
 *
 * On stderr and with a non-zero status, because the caller is usually a script
 * that will otherwise carry on and configure something that does not exist.
 */
function stop(string $why): never
{
    fwrite(STDERR, "\nInstall failed: " . $why . "\n\n");
    exit(1);
}

// ---------------------------------------------------------------------------
// The answers
// ---------------------------------------------------------------------------

/**
 * Reads the answer file, or standard input.
 *
 * The parsing, the defaults and the checks all live in public/install.php, which
 * this file already includes: the wizard writes these and reads them too, and
 * two definitions of one format is one definition too many.
 */
function read_answers(string $path): array
{
    // "-" is standard input, for the case where the answers should not exist as
    // a file at all: a provisioning tool holding the credentials in a secret
    // store can pipe them in and leave nothing on disk.
    if ($path === '-') {
        $body = stream_get_contents(STDIN);
        if ($body === false || trim($body) === '') {
            stop('Nothing arrived on standard input.');
        }
    } else {
        if (!is_file($path) || !is_readable($path)) {
            stop($path . ' cannot be read.');
        }
        $body = (string) file_get_contents($path);
    }

    [$answers, $problems] = answers_parse($body);
    if ($problems !== []) {
        refuse($problems, $path === '-' ? 'standard input' : $path);
    }
    return $answers;
}

/** The whole list, on stderr, and stop. */
function refuse(array $problems, string $where): never
{
    fwrite(STDERR, "\nThe answers in " . $where . " were refused:\n");
    foreach ($problems as $line) {
        fwrite(STDERR, '  - ' . $line . "\n");
    }
    fwrite(STDERR, "\n");
    exit(1);
}

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

$answersPath = '';
$dryRun = false;
$force  = false;

for ($i = 1; $i < $argc; $i++) {
    switch ($argv[$i]) {
        case '--example':
            fwrite(STDOUT, answers_export(answers_defaults()) . "\n");
            exit(0);
        case '--answers':
        case '-a':
            $answersPath = (string) ($argv[++$i] ?? '');
            break;
        case '--dry-run':
        case '-n':
            $dryRun = true;
            break;
        // Overwrites an existing src/config.local.php. Separate from
        // deploy: erase on purpose - one destroys a configuration, the other
        // destroys a collection, and conflating them is how the wrong one
        // happens.
        case '--force':
        case '-f':
            $force = true;
            break;
        case '--quiet':
        case '-q':
            $QUIET = true;
            break;
        case '--help':
        case '-h':
            fwrite(STDOUT, <<<TXT

RetroVault installer.

  php bin/install.php --example > install.ini
  php bin/install.php --answers install.ini [--dry-run] [--force]

  --example    print an answer file to start from
  --answers    the answer file to install from, or - for standard input
  --dry-run    check everything and touch nothing
  --force      overwrite an existing src/config.local.php
  --quiet      say nothing unless something goes wrong

Silent, for a provisioning run:

  RETROVAULT_DB_PASS=... RETROVAULT_ADMIN_PASS=... \
    php bin/install.php --answers install.ini --quiet || handle-failure

RETROVAULT_DB_PASS and RETROVAULT_ADMIN_PASS override db.pass and
admin.password, so the answer file can be templated and hold no secret. Or pipe
the whole thing in and leave nothing on disk:

  vault read -field=answers secret/retrovault | php bin/install.php --answers -

The answer file holds passwords unless the environment supplies them. chmod 600
it, and delete it afterwards.


TXT);
            exit(0);
        default:
            stop('Unknown argument "' . $argv[$i] . '". Try --help.');
    }
}

if ($answersPath === '') {
    stop('Nothing to install from. Try --example, then --answers.');
}

$a = read_answers($answersPath);
if (($bad = answers_check($a)) !== []) {
    refuse($bad, $answersPath === '-' ? 'standard input' : $answersPath);
}

// ---------------------------------------------------------------------------
// 1. Is this machine capable, and is it already installed
// ---------------------------------------------------------------------------

note($dryRun ? 'Checking, and changing nothing.' : 'Installing RetroVault.');

$blocking = [];
foreach (requirements() as $r) {
    if (($r['ok'] ?? true) === false && ($r['fatal'] ?? true)) {
        $blocking[] = (string) $r['label'] . ': ' . (string) ($r['detail'] ?? 'missing');
    }
}
if ($blocking !== []) {
    fwrite(STDERR, "\nThis server cannot run RetroVault yet:\n");
    foreach ($blocking as $line) { fwrite(STDERR, '  - ' . $line . "\n"); }
    fwrite(STDERR, "\n");
    exit(1);
}
say('Server requirements met');

if (config_exists() && !$force) {
    stop(pretty_path(CONFIG_FILE) . ' already exists. Use --force to overwrite it,'
       . ' after deciding whether the instance it describes is still wanted.');
}

// ---------------------------------------------------------------------------
// 2. The database
// ---------------------------------------------------------------------------

try {
    $pdo = pdo_connect((string) $a['db']['host'], (int) $a['db']['port'],
                       (string) $a['db']['name'], (string) $a['db']['user'],
                       (string) $a['db']['pass']);
} catch (Throwable $e) {
    stop('Could not connect to the database: ' . $e->getMessage());
}
say('Connected to ' . $a['db']['name'] . ' on ' . $a['db']['host']);

$counts = existing_data_counts($pdo);
if ($a['install']['deploy'] === 'install' && has_real_data($counts)) {
    stop('That database already holds a collection. Use deploy => "erase" to destroy it,'
       . ' or deploy => "keep" to leave it alone.');
}
// An erase that has not said it means it.
//
// The same rule the wizard applies, and for the same reason: an answer file gets
// copied between machines, and the collection it destroys is whichever database
// it happens to name that day. `deploy = erase` says what to do; `force_erase`
// is the second sentence that says it was meant.
if ($a['install']['deploy'] === 'erase' && !$a['install']['force_erase']) {
    stop('deploy is "erase", which destroys the collection in ' . $a['db']['name']
       . '. Set force_erase = 1 in the [install] section to confirm that.');
}

if ($a['install']['deploy'] === 'erase' && has_real_data($counts)) {
    say('Will erase: ' . implode(', ', array_map(
        fn($v) => counted((int) $v['n'], (string) $v['one'], (string) $v['many']),
        array_values($counts))));
}

if ($dryRun) {
    note('The answers are good and the database is reachable. Nothing was written.');
    exit(0);
}

if ($a['install']['deploy'] === 'erase') {
    drop_retrovault_tables($pdo);
    say('Existing structure dropped');
    if ($a['install']['erase_uploads']) {
        $purge = purge_uploads();
        say(sprintf('Uploads: %d of %d files deleted',
                    (int) ($purge['removed'] ?? 0), (int) ($purge['seen'] ?? 0)));
    }
}

if ($a['install']['deploy'] === 'install' || $a['install']['deploy'] === 'erase') {
    [$errs, $msgs] = run_sql_file($pdo, SCHEMA_FILE);
    if ($errs > 0) {
        stop('The schema did not load: ' . implode(' | ', $msgs));
    }
    say('Structure created');
    say(counted(installer_baseline($pdo), 'migration recorded', 'migrations recorded'));
    // Always, whatever was chosen about starter data: db/seed.sql is the auth
    // methods and platform classes the software cannot run without. Skipping it
    // leaves an instance nobody can sign in to, which is not what "start empty"
    // means.
    run_sql_file($pdo, SEED_FILE);
    say('Core records created');
} else {
    say('Database left untouched');
}

// ---------------------------------------------------------------------------
// 3. The configuration
// ---------------------------------------------------------------------------

$config = config_php([
    'written_at'      => date('j M Y, H:i'),
    'app_name'        => (string) $a['instance']['name'],
    'app_tagline'     => (string) $a['instance']['tagline'],
    'currency'        => (string) $a['instance']['currency'],
    'timezone'        => (string) $a['instance']['timezone'],
    'base_url'        => (string) $a['instance']['url'],
    'trusted_proxies' => (string) $a['instance']['trusted_proxies'],
    'db_host'         => (string) $a['db']['host'],
    'db_port'         => (int) $a['db']['port'],
    'db_name'         => (string) $a['db']['name'],
    'db_user'         => (string) $a['db']['user'],
    'db_pass'         => (string) $a['db']['pass'],
]);

if (@file_put_contents(CONFIG_FILE, $config) === false) {
    stop('Could not write ' . pretty_path(CONFIG_FILE) . '. Check who owns src/.');
}
@chmod(CONFIG_FILE, 0640);
say('Configuration written to ' . pretty_path(CONFIG_FILE));

// ---------------------------------------------------------------------------
// 4. The application, which can boot now
// ---------------------------------------------------------------------------

foreach (['helpers', 'proxy', 'db', 'auth', 'throttle', 'acl', 'log', 'ldap',
          'metadata', 'version', 'migrate', 'images', 'models', 'notify',
          'registration', 'templates'] as $unit) {
    require APP_ROOT . '/src/' . $unit . '.php';
}

if ($a['install']['deploy'] !== 'keep') {
    // create_user(), not an insert: the users table has required columns this
    // script has no business knowing about, and a hand-rolled row fails quietly.
    $uid = create_user((string) $a['admin']['username'], (string) $a['admin']['password'],
                       (string) ($a['admin']['display_name'] ?: $a['admin']['username']),
                       'admin', (string) $a['admin']['email']);
    if (!$uid) {
        stop('The administrator account could not be created.');
    }
    $user = one('SELECT * FROM users WHERE id = ?', [(int) $uid]);
    set_acting_user($user);
    say('Administrator ' . $a['admin']['username'] . ' created');
} else {
    $user = one('SELECT * FROM users WHERE role = "admin" AND is_active = 1 ORDER BY id LIMIT 1');
    if ($user === null) {
        stop('deploy is "keep" but there is no administrator in that database.');
    }
    set_acting_user($user);
}

// The name and address again, in the settings table this time. The file is what
// the software reads at boot; these are what the screens show and what mail is
// built from, and an instance with one and not the other is half configured.
set_setting('instance_name', (string) $a['instance']['name']);
if (trim((string) $a['instance']['url']) !== '') {
    set_setting('site_url', rtrim((string) $a['instance']['url'], '/'));
}

// ---------------------------------------------------------------------------
// 5. Starter data and the first library
// ---------------------------------------------------------------------------

if ($a['install']['templates'] !== 'none') {
    [$summary, $errors] = template_sync($a['install']['templates'] === 'remote');
    foreach (array_slice($errors, 0, 3) as $problem) {
        say('WARNING ' . $problem);
    }
    say(sprintf('Starter data fetched from %s: %d added',
                $a['install']['templates'] === 'remote' ? 'the published copies' : 'this checkout',
                array_sum(array_column($summary, 'added'))));
    // The counts go into the log by way of template_sync(), so an install leaves
    // the same trail a later sync does and the settings screen has something to
    // compare against from the first day.
}

if ($a['install']['deploy'] !== 'keep') {
    $libId = (int) ensure_first_library((int) $user['id']);
    say('First library created');

    if ($a['install']['templates'] !== 'none') {
        $GLOBALS['__membership_cache'] = [];
        $copied = seed_library_hardware($libId);
        say(sprintf('Copied into the library: %d machines', $copied));
        if ($a['install']['examples']) {
            seed_library_examples($libId);
            say('Example entries added');
        }
    }
}

note('Done. Delete ' . pretty_path(APP_DIR . '/public/install.php') . ' and the answer file.');
exit(0);
