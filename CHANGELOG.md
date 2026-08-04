# Changelog

**Web**

- **Artwork and photographs are two sections**, on the form as well as the entry. They answer
  different questions — what the release looks like, and what your copy looks like — and listing
  them together in upload order put a scan of the box between two photographs of a shelf. The
  split is on `provenance`, which the metadata agents already set.
- **"Artwork"**, one word, replacing *Official box art* and *Stock photos*.

**Installer**

- **Metadata sources are tested before they are switched on**, by both installers. They used to
  be added unconditionally, so an instance could come up with a source that had moved, gone, or
  was refusing this network — and the first anybody knew was a lookup that half worked, months
  later, with no way to tell which source was at fault. Each one is probed with the same check
  the Test button uses, against the term the source itself declares. One that does not answer is
  **not added**, is named on the summary, and is written to the instance's metadata log — an
  unattended install has nobody reading the terminal.

All notable changes to RetroVault are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[semantic versioning](https://semver.org/).

## [0.5.0] — unreleased

First public release.

### Added

**Catalogue**

- Separate **hardware** and **software** catalogues: machines, peripherals, games and
  applications, each with their own fields.
- A **category tree per machine**. Every branch declares what it holds, and branches beneath it
  inherit that unless they say otherwise.
- **Machine and software models**: define an Amiga 500 or a boxed cartridge once, and every
  copy inherits its specification, contents and media.
- **What is fitted to what** — an accelerator in an A1200, a SIMM on the accelerator.
- Photographs with box, manual and media condition; loans; purchase and sale records; and
  arbitrary specification rows per entry.

**Libraries**

- Any number of libraries, private or shared, each with its own locations, companies,
  platforms, categories and models.
- Six access levels per library: **Library Viewer, Contributor, Editor, Curator, Admin,
  Owner** — from reading to owning, with membership by invitation.

**Installing**

- **Fixed: a command line install as root left files the web server could not read.** The
  wizard runs as the web server and never had the problem; a shell does not, so
  `src/config.local.php` came out `root:root` at 0640 and the site answered 503 with nothing in
  any log. `bin/install.php` now sets the owner of the configuration and of `public/uploads`
  when it is root, taking the account from the new `[server]` section or looking for `wwwrun`,
  `www-data`, `apache`, `nginx` and `http`.
- **`bin/install.php --interactive`** asks the questions instead of needing a file, checking
  each answer as it is given and not echoing passwords. `--save-answers` writes the result out
  afterwards, so a machine done by hand can install the next one unattended.
- **`bin/install.php`** installs from an answer file instead of seven pages of questions:
  `--example` prints one, `--dry-run` checks everything and writes nothing, and the exit status
  is 0 only if the install finished. It includes the web installer for its helpers rather than
  keeping a second copy of them to drift. Every complaint about the answers is reported at once.
- The answer file is now the **response file**: `.rsp` rather than `.ini`, and the drop zone
  reads *Response configuration*. Still INI in shape, and `.ini` is still accepted by the file
  picker.
- The web installer **writes an answer file** on its review step and again at the end, and
  **reads one** on its first,
  so the second machine is one page and a drop rather than seven pages of the same answers. The
  file is checked as it lands. A complete one — credentials included, database answering —
  skips the remaining five pages and installs on the spot; one with the credentials still blank
  fills the pages in instead; an unusable one is marked and the ordinary installation carries
  on underneath. `deploy = erase` stops to be confirmed unless the file also says
  `force_erase = 1`, in both installers: an answer file gets copied between machines, and the
  collection it destroys is whichever database it happens to name that day.
- **Fixed: `delete_installer` broke the command line installer.** Everything the two share —
  the requirement checks, the database work, the answer file — was in `public/install.php`, so
  deleting the wizard took half of `bin/install.php` with it and the next run died on a missing
  require. That half now lives in `src/installer.php`, which nothing deletes.
- `delete_installer` removes `public/install.php` when the install finishes, and `sign_in`
  lands the browser on the instance already signed in as the administrator it just made. Both
  off unless the answer file turns them on.
- A section written twice in an answer file is refused. `parse_ini_string()` keeps the last and
  discards the first without a word, which for `deploy` is the difference between rebuilding a
  database and leaving it alone.
  No username or password is written into it: those come out as `change-…-here`, and a file
  still carrying one is refused rather than installed with a database user by that name.
- The answer file is INI, parsed by `parse_ini_string()` and executed never — the wizard takes
  one by upload, and `require` on an uploaded file is remote code execution wearing a hat. One
  definition, in `public/install.php`, used by both installers.
- `--quiet` now says nothing at all when it works, with the reason on stderr and a non-zero
  status when it does not. `RETROVAULT_DB_PASS` and `RETROVAULT_ADMIN_PASS` override the two
  passwords so the answer file can be templated and hold no secret, and `--answers -` reads it
  from standard input so it need not exist on disk.

**Web**

- The image set a lookup fills is **Stock images** on both domains, in the form, the entry and
  the lookup review — it was Artwork in one place and Stock photos in another. `image_sections()`
  feeds the selects, so the name is now decided once.

**Audit, continued**

- **A pending registration now tells every admin**, in-app and by mail. `notify_admins()` was
  written and had no caller; a signup needing approval reached the security log and nothing else,
  so an admin who was not reading it that day found out when somebody asked why they still could
  not sign in. The link goes straight to `/manage/users`.
- **`item.lent_overdue` was a registered notification kind for a feature that no longer exists.**
  Lending was removed earlier tonight; this one entry was missed because nothing triggered it, so
  it never surfaced as broken — only as unused. Removed, and its slot in `notification_kinds()`
  taken by the new registration kind rather than left as a gap.
- **A test in `retrovault-tools` still referenced the removed kind** and only failed once the
  full suite ran after this change — a reminder that a single file's suite passing is not the
  same question as the whole tree agreeing with itself. Updated to exercise the same preference
  logic against `registration.pending` instead.

- **`rule_status()` was written and never called.** Both the form and the API still had their own
  inline `in_array(...) ? ... : 'owned'` for the status field it was built for. Both now call it,
  and `tests/fields.php` asserts they do — the same gap `rule_box_state()` had until this pass.
- **Fixed: `hardware_detail()` was written, documented, and never called.** It resolves "the
  entry's own value, or the model's if the entry has none" — its own doc comment says this exists
  to stop two pages disagreeing about which one wins. Nothing called it, so the entry page read
  `item_hardware` raw: any machine with a model set but nothing retyped onto the entry itself
  showed a **blank** model, interface, and fits field, when the model had the answer all along.
  Wired into the entry view's data and the Specification table. The edit form's pre-fill
  deliberately still reads the raw row — resolving there would silently write the model's value
  onto the entry as if someone had typed it.
- **Three functions in `installer.php` were dead**, superseded by a separately-evolved, actually
  wired implementation in `src/migrate.php` + `update.php`. Removed.
- **Four more removed**: `shared_library_ids` (a duplicate of a call made directly elsewhere),
  `log_count` (the one caller that would want it computes its own count instead),
  `metadata_debug_clear` (redundant with the reset `metadata_debug_on()` already does),
  `parts_fitting_model` (written for a model detail page that was never built — no route reaches
  one). `docs/TAXONOMY.md` referenced the last of these; corrected.
- **`notify_admins()` was found complete and unwired**; documented rather than deleted or
  silently wired in, then given its own pass: a `registration.pending` notification kind and a
  call beside the security-log line that already existed. An admin who signs up needing approval
  is told now, in-app and by mail, rather than only whoever next reads the log.
- **`store_logo()` was wrongly flagged as an unwired feature, and it was not one.** I checked
  whether that exact name was called, found it was not, and concluded company logos had no way in
  — without checking whether a *differently named* function already did the job. It does:
  `store_company_logo()` and `delete_company_logo()` are a complete, separately-written pair,
  fully wired through `taxonomy_save()` and a file input already sitting in the generic taxonomy
  edit form. Uploading a company logo has worked the whole time. `store_logo()` and its sibling
  `delete_logo()` — a generic pair for "companies or vendors", from before vendors merged into
  companies — were the genuinely dead ones, and are removed now that the working replacement is
  confirmed rather than assumed.
- **A first automated pass over-reported**: it flagged `metadata_search_amigahw`,
  `metadata_platforms_thegamesdb` and four others as dead. All are reached through
  `'metadata_search_' . $type` / `'metadata_platforms_' . $type` dispatch, not a literal call —
  checked individually against `metadata_provider_types()` before anything was touched. Two of
  the flagged names, `mobygames` and `csdb`, turned out to be **deliberately withdrawn features**
  with a test asserting they stay unused while their parsers remain reachable by name.

**API**

- **`src/rules.php`** — the rules an entry obeys, in one place, called by both the web form and
  the API. The same question had two answers before: `condition` was a validated enum on one side
  and free text on the other, and the rule that clearing "there is a box" also clears the box
  grade existed twice, in different words, with no reason to think they agreed.
- What is shared is the **rule**; what is not is the **policy on a bad value**. Each function
  returns null for "that is not one of these", and the form falls back to `unknown` while the API
  answers 422 — a person mid-page should not lose it to a select that cannot be wrong anyway, and
  a client that sent nonsense wants to know. Making those identical would have been a change to
  the web, dressed up as a refactor.

- The entry payload returns **`acquired_from`, `acquired_note`, `sold_to`, `sold_note` and
  `sold_currency`**. All five became writable last round and none was returned, so a client could
  set who a thing came from and never read it back.

- **Fixed: compatibility was read from one of the two places it is declared.** A model may name
  the machines it fits, and a single card may name them itself through `item_fits` — the
  *Compatible hardware* checkboxes on the web form. The check read only the model's list, so a
  peripheral whose compatibility had been recorded by hand looked like one that had said nothing:
  the answer came out right for the wrong reason, until somebody set a model, at which point it
  came out wrong. It calls `effective_fits()` now, which already knows the precedence.
- **Fixed: a machine with no model was refused by every peripheral that declared what it fits.**
  The check compared the machine's `model_id` to the peripheral's list and, finding NULL, read it
  as 0 and refused. Every machine in a fresh catalogue has no model — so the better a peripheral
  was catalogued, the more certainly it was rejected. Two silences, both meaning "cannot tell":
  a peripheral naming nothing goes anywhere, and a machine with no model cannot be checked
  against a list of models at all.
- **A maker or publisher can be sent by name.** `developer` and `publisher` accept a string and
  match it case-insensitively, by name then by slug, creating the company only when nothing
  matches. The app used to refuse — "add it under Companies on the web" — which is a phone
  telling somebody to go and find a computer. A near-match is **named in the log**: a source
  answering "Team17 Software Limited" to a library holding "Team17" is describing one firm, and
  no rule here can be sure of that, since the same rule would merge Sega and Sega Europe.

- **Fixed: the API has never handled a location.** Not by id, not by path — so "Where it is kept"
  on the phone was typed, sent and silently dropped. `location_path` is accepted now, matched on
  the breadcrumb somebody reads rather than on `locations.path`, which looks like the answer and
  is not: that column holds an id path (`/1/7/`) for subtree queries. Matching against it would
  have found nothing a client ever sends, with a test cheerfully saying the field was handled.
- **Provenance is writable**: `acquired_from`, `acquired_note`, `sold_to`, `sold_note`,
  `sold_currency` and `location_position`. The web has written these since it existed and the API
  accepted none of them, so an entry created from a phone could record what it cost and not who
  it came from.

- **Lending is gone from the platform.** It was half-removed already — `status_options()` had
  dropped `lent` but the columns, the enum value, the dashboard panels, the CSV columns and the
  API fields all stayed, so a client could set a status the web would not offer. Migration 0026
  finishes it: entries marked lent become owned, and **what was recorded is appended to the
  notes** rather than dropped, because somebody who wrote down who had a thing deserves to still
  be able to read it. The `lent`/`returned` event kinds stay in `item_events` for rows already
  written — deleting somebody's history is not what removing a feature means.

- **Fixed: `can_write_library()` never existed.** I invented the name; artwork import, fitting
  and unfitting all returned 500 with *Call to undefined function*. They use `can_write_item()`,
  which is also the stricter and more correct check.
- **The rules for what may be installed in what**, enforced on the server and offered through
  `/items/{id}/links/candidates`: only hardware, only peripherals, only into machines, and only
  where the peripheral either names this machine among those it fits or names none, with
  platforms agreeing.
- `/meta` reports **`app_version`**, the server's own — distinct from the API version and from
  any client's.

- **`GET /models`** — the canonical models an entry can be filed under. `items.model_id` has been
  writable for a while with no way to discover an id to put in it, which makes a writable field a
  field nobody can use. Narrowed by `category_id` the way the web's picker narrows it: a model
  belongs to a branch, and a list of every model on an instance is not a picker but a haystack.

- **The rest of `item_hardware`**: `interface`, `provides`, `fits`, `recapped_on`, `serviced_on`,
  `manufactured_year`, and the **specification rows**. Those are a JSON column of
  `{label, value}` rather than columns, because an Amiga has a chipset and a PC has a bus and
  neither list is finite. The API decodes it before sending, so a client is not parsing JSON out
  of a JSON field.

- **`/items/{id}/links`** — what is fitted to an entry and what it is fitted to, in both
  directions, plus fitting and unfitting. `item_links` is the catalogue's one genuinely
  relational idea and the API had nothing at all for it, so a phone could see *Installed
  peripherals* on the web and not know the relationship existed. `direction` decides which way
  round, because otherwise a client would have to know which of two entries is the parent before
  it could say they are related. Loops are refused through the same `item_link_would_loop()` the
  web calls.

- **Fixed: a library made through the API was invisible to whoever made it.** `owner_id` says
  whose a library is; `library_members` decides who may *see* it, and `accessible_library_ids()`
  reads the second. Neither create route wrote that row, so the library existed, appeared under
  library management — which asks the server for everything — and was missing from the caller's
  own list and every picker built from it. The web has always written both.

- `working_state` is writable and returned with the rest of the `hardware` object — the web calls
  it **Does it work**, and it is the first thing anybody asks about a machine.

- `POST` **`/libraries`** — make a library of your own, which any signed-in account may do. The
  admin route needed an administrator, so the API was stricter than the web for the same action:
  `library_create()` on the web checks only that somebody is signed in. `POST /admin/libraries`
  stays for administering an instance.

- `POST` **`/items/{id}/images/import`** — fetch a picture from a metadata source and attach it.
  The web has had this since metadata lookup existed; the API never did, so a phone could find
  the box art and not keep it. The server does the fetching, because it already knows how to
  check what came back is an image, resize it, and notice the same picture twice. Artwork lands
  as `official` provenance, never among somebody's own photographs.

- **The fields a client could read and not write.** `condition_grade`, `has_box`,
  `condition_box`, `condition_manual`, `condition_media` and `model_id` on the entry itself, and
  `model`, `board_revision`, `firmware`, `serial_number` and `modifications` from `item_hardware`
  — none of which the API accepted, so a phone could show a serial number and not correct one.
  `modifications` is the one that mattered most: with only `notes` writable, a client had to put
  modifications in the notes, which is the confusion migration 0014 exists to end.
- The detailed view returns a **`hardware`** object, null on software and on entries nobody has
  filled in. It is a query against `item_hardware` rather than a column read, so it happens on
  the single-entry view only — a list of two hundred does not need two hundred round trips for
  fields no list shows.
- Clearing **`has_box`** clears the box grade with it, as the web form does. Grading a box that
  is not there is meaningless.

- `meta.errors` on a metadata search is **always an object**. PHP encodes an empty associative
  array as `[]` and a populated one as `{...}`, so the field changed shape depending on whether
  any source had failed — disabling a single provider was enough to break a client that decoded
  the other one.

- `POST` **`/admin/users`**, so accounts can be made from a phone. Through the same
  `create_user()` the installer uses, which gives the account its personal library on the way
  past — the one shelf everybody is promised.

- `POST` and `DELETE` **`/profile/avatar`**, so a picture can be set from a phone. Multipart into
  `store_user_avatar()`, the same path the web form takes — one place decides what a valid
  picture is and what it is resized to.

- **`/admin/libraries`** — list, create, change, delete. The list is every library, not the ones
  the caller may read: an administrator needs it complete, since a library nobody can see is one
  nobody can fix. Deleting is refused for a library that still holds anything, and for the last
  one — an instance with none has nowhere to put the next thing somebody adds. Renaming moves
  the slug with it.

- `GET` **`/admin/users`** and `PATCH` **`/admin/users/{id}`**, so account management can leave
  the browser. Two refusals rather than warnings: removing the last active administrator, and
  changing your own role — undoing that would need the role just given up.

- **A 401 says which of five things went wrong.** No header at all, a token nobody has heard of,
  a revoked one, an expired one, an account since disabled — all produced "Send a valid bearer
  token in the Authorization header", which is true of every one of them and useful for none. It
  sent people to check a header that was fine. The no-header case now names the proxy in front
  as a candidate, because a header that leaves the client and does not arrive is the hardest of
  these to reason about from either end.

- **Every API refusal is now in the log.** Nothing the API did reached the log page before: no
  sign-ins, no refusals, nothing — so an operator watching the log while being told "the app
  will not save" saw an empty screen. Refusals about who you are go in the security stream, the
  rest in the server stream, with the method, the path, the status and the fields complained
  about.
- **A token issued to a device is recorded** as `api.token.issued`, named after the device, so
  "which phone was that" has an answer.

- `GET` **`/admin/logs`** with the filters the web viewer offers, plus the per-channel counts
  and the events that have actually happened, so a client draws the same tabs without four
  requests. `GET` and `POST` **`/admin/maintenance`**: every check is run to answer the list,
  because the reason to press a repair is that its check found something, and the check is run
  again afterwards so the answer says what is left.

- `docs/openapi.yaml` describes `/notifications`, `/notifications/read` and `/metadata/search`,
  which it had never mentioned. The suite now compares the routes in `public/index.php` against
  the spec and fails on anything missing — or written twice, which YAML resolves by keeping the
  last and saying nothing.

- The API suite covers the settings endpoints: every field kind, the bounds, the all-or-nothing
  rule on a batch, and that a secret never comes back. 27 assertions to 71.

- `GET`/`PATCH` **`/profile`** and **`/profile/notifications`**: your details, your password, and
  what you want to be told about.
- `GET`/`PATCH` **`/admin/settings`**: the instance settings, described rather than dumped — each
  field carries its kind, its choices and its limits, so a native client can draw the form
  without knowing the settings in advance, and a setting added later appears in an app nobody
  rebuilt. Secrets report only whether they are set.

**Instance settings**

- The paragraph above the log streams is gone. The tabs say Security and Server; explaining what
  those mean above a screen that shows them was furniture.

- The starter-data table **moved to the library screen**, where it answers the question people
  have. It counted the template set against the files — one answer for the whole instance — and
  now counts what a library holds against what there is to copy, beside the button that copies
  it. A row is marked only when the library has fewer; the filing tree is built once per
  platform, so its branch counts are legitimately larger. Instance settings keeps the address to
  fetch from, which is genuinely instance-wide, and the button that fetches.

- **Starter data** is one table: what this instance holds of each kind against how many the
  files held when they were last fetched, marked where they disagree. Every sync records both
  numbers and writes the local ones into the server log, so "when did the peripherals go from 4
  to 21" has an answer. An install syncs, so the record exists from the first day.
- **Force update**, beside Save, resyncs ignoring what is already present. An ordinary fetch
  skips a slug it recognises, so a correction to a row that shipped wrong could never arrive.
  Neither touches a library.
- The log **Test** panel is gone; **Write test log** sits beside Save in Logging, so it saves
  and then writes rather than testing what was stored last time somebody pressed Save.

**Fixed**

- **Deleting a machine left its branch behind.** `categories.platform_id` is `ON DELETE SET
  NULL`, so removing a platform left its root standing: the filing tree went on showing the
  machine's name with nothing behind it, nothing filed under it could say what it ran on, and
  resyncing the library did not repair it — the resync matches on slug, saw the branch and
  called the machine already built. The branch now goes with the machine, and a resync relinks
  a root that lost its platform some other way.

- A maintenance job reporting **what PHP will accept**: `post_max_size`, `upload_max_filesize`,
  `memory_limit`, which `php.ini` is actually loaded and under which SAPI. It flags an
  `upload_max_filesize` above `post_max_size` — which can never be reached, because the smaller
  number caps the whole request — and limits too low for a photograph of a boxed machine. The
  installer checked this once and is then deleted, which left no way to ask a running instance.

- **A command line install switched on no metadata sources.** The wizard has always enabled the
  ones needing no account; `bin/install.php` never did, so an instance built from a response
  file came up with nothing to look titles up with and no sign it was meant to have any. Both
  now share `installer_enable_metadata_sources()`. `metadata_sources` in the response file says
  whether to, and the wizard asks on its settings step — ticked, which is what it has always
  done without asking.

- A maintenance job for **specification names whose machine is gone**. Deleting a library takes
  its platforms and leaves the vocabulary behind pointing at rows that no longer exist —
  `ON DELETE SET NULL` on the category side, nothing at all on this one. Nothing read them and
  nothing counted them, and they accumulated: 4,552 on a database that had been used for a
  while.
- The maintenance API sent an **empty message for every job**. `maintenance_result()` calls it
  `note` and the endpoint read `message`, so the native screen showed a count and no sentence.

- **Specification names read 1158 against 589 on a freshly installed instance**, in red, with
  nothing wrong. `seed_library_hardware()` copies the interface vocabulary for a library's own
  platforms — a library with platforms and not the words for what plugs into them cannot
  describe a card — so the table grows by roughly the file's size with every library made. The
  count now takes the template rows only, and holds still as libraries are added.

- The **peripheral model count** on the settings screen read 0 while twenty-one were filed. It
  tested `role = 'peripheral'` on the model's own branch, and the tree declares that kind on the
  branch that means it — Expansions — with everything under it inheriting. A model is either a
  machine or a part, so it is counted as the counterpart of the machine line.
- Choosing a company on a **model or hardware entry** narrows the platform list only when the
  thing is a machine. A machine's maker built the platform; a peripheral's usually did not — a
  Phase 5 accelerator goes in a Commodore machine — and narrowing there removed the Amiga from
  the list and reset the platform on a model that had one.

**Metadata**

- Lookup against **OpenRetro, TheGamesDB, IGDB, the Amiga Hardware Database, the Big Book of
  Amiga Hardware, TheRetroWeb, Wikipedia, Wikimedia Commons and Wikidata**.
- Which sources answer for which branch is decided in the category tree and inherited
  downward.
- Nothing is written without review: every field and every image is offered and applied only
  when ticked.
- **Save and look up** on the entry forms, offered when the branch being filed into has a
  source switched on.

**Accounts and access**

- Local accounts, or sign-in through **LDAP / Active Directory** with group-to-role mapping.
- Registration modes: closed, public, by secret address, or by invitation — with optional
  email confirmation or administrator approval.
- API tokens for mobile and third-party clients.

**Running it**

- Browser installer with requirement checks, or a command-line install.
- Starter data for 63 machines, fetched from GitHub or the shipped copies. An instance
  running against template files older than itself still arrives working: what is a judgement
  rather than data lives in the code, and the tree is repaired on both sides if the fetched
  copy declares nothing.
- Maintenance jobs for the things that drift: orphaned photographs, photograph rows whose file
  is gone, branches with no machine, machines with no branch, blurbs left in notes.
- Syslog or file logging, SMTP with a proven-delivery check, and a `/healthz` endpoint for a
  load balancer.
