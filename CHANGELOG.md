# Changelog

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
