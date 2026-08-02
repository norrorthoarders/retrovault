# RetroVault

A self-hosted catalogue for a retro computing collection: the machines, the cards fitted inside
them, the boxed software on the shelf, and where all of it is kept.

PHP 8.3 and MariaDB, with no build step and no JavaScript framework.

## What it does

- **Hardware and software, catalogued differently.** A machine has a processor and a serial
  number; a boxed game has a manual and a disk. They are not filed as though they were the same.
- **A category tree per machine**, which you arrange. Each branch says what it holds and
  everything beneath inherits that.
- **Models.** Describe an Amiga 500 once; every one you add inherits its specification. The same
  for a boxed release and what should be in the box.
- **What is fitted to what** — an accelerator in an A1200, a SIMM on the accelerator.
- **Metadata lookup** against nine sources, chosen per branch, reviewed before anything is
  written.
- **Any number of libraries**, private or shared, with six access levels and invitations.
- **Photographs, loans, purchase and sale records, condition**, and a value for the collection.
- **A JSON API** for the iOS and Android clients, and for anything else you point at it.

## Requirements

- PHP 8.3 with `pdo_mysql`, `mbstring`, `gd` or `imagick`, `curl`, and `ldap` if you want
  directory sign-in
- MariaDB 10.11 or MySQL 8
- Apache or nginx, serving `public/` as the document root
- HTTPS — sessions and API tokens travel in headers

## Installing

1. Point a virtual host at `public/`.
2. Create an empty database and a user with rights to it.
3. Open the site in a browser. The installer checks the requirements, writes
   `src/config.local.php`, loads the schema, and offers the starter data for 63 machines.

Or without a browser, which is the right way for the twentieth machine and the only way for
one that has to come up unattended:

```
php bin/install.php --interactive               # or, asked at the terminal
php bin/install.php --example > install.ini      # or download one from the wizard
php bin/install.php --answers install.ini --dry-run
php bin/install.php --answers install.ini --quiet
```

The last page of the web installer writes one of these files from the answers it was just
given, and its first page reads one back — so the second machine needs neither the wizard nor a
hand-written file. No username or password is saved into it.

`bin/install.php` reads the answers rather than asking them, and does the same work in the same
order using the same code. `--dry-run` checks the answers, the server and the database and
writes nothing. `--quiet` says nothing at all unless something goes wrong, and the exit status
is 0 only if the install finished — which is what a provisioning script needs and what a web
page cannot give it. `RETROVAULT_DB_PASS` and `RETROVAULT_ADMIN_PASS` override the two
passwords, so the answer file can be templated and hold no secret; `--answers -` reads it from
standard input, so it need not exist on disk at all.
[docs/INSTALL.md](docs/INSTALL.md) has the full list of what the answer file decides.

Upgrading is `git pull` followed by `php bin/migrate.php up`.

## Documentation

[CHANGELOG.md](CHANGELOG.md) · [SECURITY.md](SECURITY.md) · [LICENSE.md](LICENSE.md) ·
[docs/](docs/)

## Licence

GNU General Public License v3.0. Free to run, read, change and share; a changed version you
distribute stays under the same licence.

Tommy Frössman — <frossmant@gmail.com>
