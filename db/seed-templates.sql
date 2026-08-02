-- ---------------------------------------------------------------------------
-- Starter data.
--
-- Machines, makers, studios, genres, types. Optional: the installer asks, and
-- an instance that says no starts empty. The same content is in db/templates/
-- as JSON, which is what the synchronise button reads; this file exists so an
-- install with no network still has the option.
--
-- Everything here is a template row - library_id NULL where the table has it -
-- copied into a library when one is created, never filed under directly.
-- ---------------------------------------------------------------------------

-- The same columns companies carries, so a maker and a studio record the same
-- facts. Logos are not seeded: they are files, and the starter data ships none.
INSERT IGNORE INTO companies
  (library_id, name, slug, country, founded_year, defunct_year, website, wikipedia_url, notes) VALUES
  (NULL, 'Commodore', 'commodore', 'US', 1954, 1994, NULL, 'https://en.wikipedia.org/wiki/Commodore_International', NULL),
  (NULL, 'Sinclair', 'sinclair', 'GB', 1973, NULL, NULL, 'https://en.wikipedia.org/wiki/Sinclair_Research', NULL),
  (NULL, 'Atari', 'atari', 'US', 1972, NULL, NULL, 'https://en.wikipedia.org/wiki/Atari', NULL),
  (NULL, 'Amstrad', 'amstrad', 'GB', 1968, NULL, NULL, 'https://en.wikipedia.org/wiki/Amstrad', NULL),
  (NULL, 'Acorn', 'acorn', 'GB', 1978, 2000, NULL, 'https://en.wikipedia.org/wiki/Acorn_Computers', NULL),
  (NULL, 'Apple', 'apple', 'US', 1976, NULL, 'https://www.apple.com', 'https://en.wikipedia.org/wiki/Apple_Inc.', NULL),
  (NULL, 'Nintendo', 'nintendo', 'JP', 1889, NULL, 'https://www.nintendo.com', 'https://en.wikipedia.org/wiki/Nintendo', NULL),
  (NULL, 'Sega', 'sega', 'JP', 1960, NULL, 'https://www.sega.com', 'https://en.wikipedia.org/wiki/Sega', NULL),
  (NULL, 'Sony', 'sony', 'JP', 1946, NULL, 'https://www.sony.com', NULL, NULL),
  (NULL, 'NEC', 'nec', 'JP', 1899, NULL, 'https://www.nec.com', NULL, NULL),
  (NULL, 'Sharp', 'sharp', 'JP', 1912, NULL, 'https://global.sharp', NULL, NULL),
  (NULL, 'Fujitsu', 'fujitsu', 'JP', 1935, NULL, 'https://www.fujitsu.com', NULL, NULL),
  (NULL, 'SNK', 'snk', 'JP', 1978, NULL, NULL, NULL, NULL),
  (NULL, 'Bandai', 'bandai', 'JP', 1950, NULL, 'https://www.bandai.com', NULL, NULL),
  (NULL, 'Mattel', 'mattel', 'US', 1945, NULL, 'https://www.mattel.com', NULL, NULL),
  (NULL, 'Philips', 'philips', 'NL', 1891, NULL, 'https://www.philips.com', 'https://en.wikipedia.org/wiki/Philips', NULL),
  (NULL, 'Tandy', 'tandy', 'US', 1919, NULL, NULL, NULL, NULL),
  (NULL, 'Luxor', 'luxor', 'SE', 1923, 1984, NULL, 'https://en.wikipedia.org/wiki/Luxor_AB', NULL),
  (NULL, 'IBM', 'ibm', 'US', 1911, NULL, 'https://www.ibm.com', 'https://en.wikipedia.org/wiki/IBM', NULL),
  (NULL, 'Phase 5', 'phase-5', 'DE', NULL, 2001, NULL, NULL, NULL),
  (NULL, 'Great Valley Products', 'gvp', 'US', NULL, 1998, NULL, NULL, NULL),
  (NULL, 'Commodore Semiconductor', 'csg', 'US', NULL, 1994, NULL, NULL, NULL),
  (NULL, 'Creative Labs', 'creative', 'SG', 1981, NULL, 'https://www.creative.com', 'https://en.wikipedia.org/wiki/Creative_Technology', NULL),
  (NULL, 'Various', 'various-vendor', NULL, NULL, NULL, NULL, NULL, NULL),
  (NULL, 'W.A.W. Elektronik', 'waw-elektronik', 'DE', NULL, NULL, NULL, NULL, NULL),
  (NULL, 'MNT Research', 'mnt-research', 'DE', 2015, NULL, 'https://mntre.com', 'https://en.wikipedia.org/wiki/MNT_Reform', NULL);

-- Platforms are staged so the maker named on each row becomes a row of its own
-- rather than the same word typed into sixty-three columns.
CREATE TEMPORARY TABLE seed_platforms (
  name            VARCHAR(120) NOT NULL,
  slug            VARCHAR(140) NOT NULL,
  maker           VARCHAR(120) DEFAULT NULL,
  year_introduced INT          DEFAULT NULL,
  accent_color    CHAR(7)      NOT NULL DEFAULT '#cba6f7',
  sort_order      INT          NOT NULL DEFAULT 100,
  -- What kind of machine, so a platform nobody has modelled still gets the right
  -- category tree instead of defaulting to a computer's.
  machine_class   VARCHAR(16)  NOT NULL DEFAULT 'computer',
  PRIMARY KEY (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO seed_platforms (name, slug, maker, year_introduced, accent_color, sort_order) VALUES
  ('Amiga',             'amiga',        'Commodore',   1985, '#f38ba8', 10),
  ('C64',               'c64',          'Commodore',   1982, '#a6e3a1', 20),
  ('MSX / MSX2',        'msx',          'ASCII/Microsoft', 1983, '#89b4fa', 30),
  ('Atari ST',     'atari-st',     'Atari',       1985, '#fab387', 40),
  ('ZX Spectrum',       'zx-spectrum',  'Sinclair',    1982, '#f9e2af', 50),
  ('Amstrad CPC', 'amstrad-cpc',  'Amstrad',     1984, '#94e2d5', 60),
  ('NES',               'nes',          'Nintendo',    1983, '#eba0ac', 80),
  ('Mega Drive',        'mega-drive',   'Sega',        1988, '#74c7ec', 90),
  ('VIC-20',            'vic-20',       'Commodore',   1980, '#b4befe', 100);

-- The machine, distinct from whatever it boots.
INSERT IGNORE INTO seed_platforms (name, slug, maker, year_introduced, accent_color, sort_order)
VALUES ('PC', 'pc', 'IBM and compatibles', 1981, '#94e2d5', 15);

-- Software types ------------------------------------------------------------

-- Genres --------------------------------------------------------------------

-- A few companies to get autocomplete going ---------------------------------
INSERT IGNORE INTO companies (name, slug, country, founded_year, website) VALUES
  ('Psygnosis',        'psygnosis',        'United Kingdom', 1984, NULL),
  ('Team17',           'team17',           'United Kingdom', 1990, 'https://www.team17.com/'),
  ('DMA Design',       'dma-design',       'United Kingdom', 1987, NULL),
  ('Bitmap Brothers',  'bitmap-brothers',  'United Kingdom', 1987, NULL),
  ('Sensible Software','sensible-software','United Kingdom', 1986, NULL),
  ('Digital Illusions','digital-illusions','Sweden',         1992, NULL),
  ('Electronic Arts',  'electronic-arts',  'United States',  1982, 'https://www.ea.com/'),
  ('Konami',           'konami',           'Japan',          1969, 'https://www.konami.com/'),
  ('Ocean Software',   'ocean-software',   'United Kingdom', 1983, NULL),
  ('Commodore',        'commodore',        'United States',  1954, NULL);

-- Tags ----------------------------------------------------------------------
INSERT IGNORE INTO tags (name, slug) VALUES
  ('Budget re-release', 'budget-rerelease'),
  ('Big box',           'big-box'),
  ('Sealed',            'sealed'),
  ('Nordic release',    'nordic-release'),
  ('Signed',            'signed'),
  ('Needs cleaning',    'needs-cleaning');

-- ---------------------------------------------------------------------------
-- Wider platform coverage. Still INSERT IGNORE on slug, so re-running adds
-- only what is missing and never disturbs a library you have edited.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO seed_platforms (name, slug, maker, year_introduced, accent_color, sort_order) VALUES
  -- Commodore
  ('PET',        'pet',            'Commodore',        1977, '#b4befe', 110),
  ('Plus/4',     'plus4',          'Commodore',        1984, '#f5c2e7', 120),
  ('Amiga CD32',           'cd32',           'Commodore',        1993, '#f38ba8', 130),
  ('CDTV',       'cdtv',           'Commodore',        1991, '#eba0ac', 140),

  -- Sinclair and friends
  ('ZX81',        'zx81',           'Sinclair',         1981, '#bac2de', 150),
  ('QL',          'sinclair-ql',    'Sinclair',         1984, '#cba6f7', 160),
  ('SAM Coupe',            'sam-coupe',      'MGT',              1989, '#f5e0dc', 170),

  -- Acorn
  ('BBC Micro',            'bbc-micro',      'Acorn',            1981, '#f9e2af', 180),
  ('Electron',       'acorn-electron', 'Acorn',            1983, '#f5e0dc', 190),
  ('Archimedes',     'archimedes',     'Acorn',            1987, '#fab387', 200),
  ('RISC PC',        'risc-pc',        'Acorn',            1994, '#eba0ac', 210),

  -- Amstrad
  ('PCW',          'amstrad-pcw',    'Amstrad',          1985, '#fab387', 220),

  -- Nordic machines
  ('Compis',               'compis',         'TeleNova / Svenska Datorer', 1985, '#94e2d5', 230),
  ('ABC 80',         'abc-80',         'Luxor',            1978, '#a6e3a1', 240),
  ('ABC 800',        'abc-800',        'Luxor',            1981, '#89dceb', 250),

  -- Other 8-bit computers
  ('II',             'apple-ii',       'Apple',            1977, '#a6e3a1', 260),
  ('8-bit',          'atari-8bit',     'Atari',            1979, '#fab387', 270),
  ('TRS-80',         'trs-80',         'Tandy',            1977, '#a6adc8', 280),
  ('Dragon 32/64',         'dragon-32',      'Dragon Data',      1982, '#a6e3a1', 290),
  ('Oric-1 / Atmos',       'oric',           'Tangerine',        1983, '#f9e2af', 300),
  ('MO/TO',        'thomson',        'Thomson',          1982, '#f5c2e7', 310),
  ('MZ series',      'sharp-mz',       'Sharp',            1978, '#94e2d5', 320),

  -- 16/32-bit computers
  ('Macintosh 68k',  'mac-68k',        'Apple',            1984, '#cdd6f4', 330),
  ('X68000',         'x68000',         'Sharp',            1987, '#89b4fa', 340),
  ('PC-8801',          'pc-8801',        'NEC',              1981, '#74c7ec', 350),
  ('PC-9801',          'pc-9801',        'NEC',              1982, '#89dceb', 360),
  ('FM Towns',     'fm-towns',       'Fujitsu',          1989, '#b4befe', 370),

  -- PC eras, kept separate because the collecting is quite different

  -- Sega
  ('SG-1000',         'sg-1000',        'Sega',             1983, '#f38ba8', 400),
  ('Master System',   'master-system',  'Sega',             1985, '#89dceb', 410),
  ('Game Gear',       'game-gear',      'Sega',             1990, '#94e2d5', 420),
  ('Mega-CD',         'mega-cd',        'Sega',             1991, '#a6e3a1', 430),
  ('32X',             'sega-32x',       'Sega',             1994, '#eba0ac', 440),
  ('Saturn',          'saturn',         'Sega',             1994, '#b4befe', 450),
  ('Dreamcast',       'dreamcast',      'Sega',             1998, '#cba6f7', 460),

  -- Nintendo
  ('Super Nintendo',       'snes',           'Nintendo',         1990, '#cba6f7', 470),
  ('Game Boy',    'game-boy',       'Nintendo',         1989, '#94e2d5', 480),
  ('64',          'n64',            'Nintendo',         1996, '#a6e3a1', 490),
  ('Game Boy Advance',     'gba',            'Nintendo',         2001, '#b4befe', 500),
  ('Virtual Boy',          'virtual-boy',    'Nintendo',         1995, '#f38ba8', 510),

  -- Atari consoles
  ('2600',           'atari-2600',     'Atari',            1977, '#f38ba8', 520),
  ('5200',           'atari-5200',     'Atari',            1982, '#fab387', 530),
  ('7800',           'atari-7800',     'Atari',            1986, '#eba0ac', 540),
  ('Lynx',           'lynx',           'Atari',            1989, '#a6e3a1', 550),
  ('Jaguar',         'jaguar',         'Atari',            1993, '#f9e2af', 560),

  -- Other consoles
  ('PC Engine',        'pc-engine',      'NEC',              1987, '#f38ba8', 570),
  ('Neo Geo AES',      'neo-geo',        'SNK',              1990, '#f9e2af', 580),
  ('PlayStation',     'playstation',    'Sony',             1994, '#bac2de', 590),
  ('3DO Interactive',      '3do',            'Panasonic / 3DO',  1993, '#89dceb', 600),
  ('CD-i',         'cd-i',           'Philips',          1991, '#b4befe', 610),
  ('Intellivision', 'intellivision',  'Mattel',           1979, '#fab387', 620),
  ('ColecoVision',         'colecovision',   'Coleco',           1982, '#a6e3a1', 630),
  ('Vectrex',              'vectrex',        'GCE / Milton Bradley', 1982, '#cdd6f4', 640),
  ('WonderSwan',    'wonderswan',     'Bandai',           1999, '#f5c2e7', 650);

-- Every studio seeded here made games. The column exists so that a spreadsheet
-- publisher has somewhere to go, not because any of these are one.
UPDATE companies SET domain = 'game' WHERE domain IS NULL OR domain = '';

-- ---------------------------------------------------------------------------
-- Drain the staging table into the template platforms.
--
-- library_id NULL marks a template: never used by an entry, copied into a
-- library when one is created. There is no shared list, so nothing here is
-- reachable until it has been copied somewhere that belongs to somebody.
-- ---------------------------------------------------------------------------
-- The class each platform is, from starter-data/platforms.json. Kept as its own
-- statement so the rows above stay readable.
UPDATE seed_platforms SET machine_class = CASE slug
  WHEN '3do' THEN 'console'
  WHEN 'atari-2600' THEN 'console'
  WHEN 'atari-5200' THEN 'console'
  WHEN 'atari-7800' THEN 'console'
  WHEN 'cd-i' THEN 'console'
  WHEN 'cd32' THEN 'console'
  WHEN 'cdtv' THEN 'console'
  WHEN 'colecovision' THEN 'console'
  WHEN 'dreamcast' THEN 'console'
  WHEN 'game-boy' THEN 'handheld'
  WHEN 'game-gear' THEN 'handheld'
  WHEN 'gba' THEN 'handheld'
  WHEN 'intellivision' THEN 'console'
  WHEN 'jaguar' THEN 'console'
  WHEN 'lynx' THEN 'handheld'
  WHEN 'master-system' THEN 'console'
  WHEN 'mega-cd' THEN 'console'
  WHEN 'mega-drive' THEN 'console'
  WHEN 'n64' THEN 'console'
  WHEN 'neo-geo' THEN 'console'
  WHEN 'nes' THEN 'console'
  WHEN 'pc-engine' THEN 'console'
  WHEN 'playstation' THEN 'console'
  WHEN 'saturn' THEN 'console'
  WHEN 'sega-32x' THEN 'console'
  WHEN 'sg-1000' THEN 'console'
  WHEN 'snes' THEN 'console'
  WHEN 'vectrex' THEN 'console'
  WHEN 'virtual-boy' THEN 'console'
  WHEN 'wonderswan' THEN 'handheld'
  ELSE 'computer' END;

INSERT IGNORE INTO platforms
    (library_id, name, slug, vendor_id, year_introduced, accent_color, machine_class)
SELECT NULL, sp.name, sp.slug, v.id, sp.year_introduced, sp.accent_color, sp.machine_class
  FROM seed_platforms sp
  LEFT JOIN companies v ON v.name = sp.maker AND v.library_id IS NULL;

DROP TEMPORARY TABLE seed_platforms;


-- ---------------------------------------------------------------------------
-- Developers and publishers of the 8- and 16-bit era.
--
-- Founded years are given only where they are well established; a wrong year is
-- worse than none, since it silently pollutes anything built on top of it.
-- Still INSERT IGNORE on slug, so this never disturbs a company you have edited.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO companies (name, slug, country, founded_year, defunct_year) VALUES
  -- United Kingdom: the bulk of the C64 and Amiga catalogue
  ('Ocean Software',          'ocean-software',        'United Kingdom', 1983, 1998),
  ('U.S. Gold',               'us-gold',               'United Kingdom', 1984, 1996),
  ('Gremlin Graphics',        'gremlin-graphics',      'United Kingdom', 1984, 1999),
  ('Codemasters',             'codemasters',           'United Kingdom', 1986, NULL),
  ('Rare',                    'rare',                  'United Kingdom', 1985, NULL),
  ('Ultimate Play the Game',  'ultimate-play-the-game','United Kingdom', 1982, 1988),
  ('Hewson Consultants',      'hewson-consultants',    'United Kingdom', 1980, 1991),
  ('Firebird Software',       'firebird-software',     'United Kingdom', 1984, 1989),
  ('Rainbird Software',       'rainbird-software',     'United Kingdom', 1985, 1989),
  ('Melbourne House',         'melbourne-house',       'United Kingdom', 1977, 1999),
  ('Mastertronic',            'mastertronic',          'United Kingdom', 1983, 1988),
  ('Elite Systems',           'elite-systems',         'United Kingdom', 1984, NULL),
  ('System 3',                'system-3',              'United Kingdom', 1982, NULL),
  ('Palace Software',         'palace-software',       'United Kingdom', 1984, 1991),
  ('Thalamus',                'thalamus',              'United Kingdom', 1986, 1993),
  ('Graftgold',               'graftgold',             'United Kingdom', 1983, 1998),
  ('Vivid Image',             'vivid-image',           'United Kingdom', 1987, NULL),
  ('Bullfrog Productions',    'bullfrog',              'United Kingdom', 1987, 2001),
  ('Magnetic Scrolls',        'magnetic-scrolls',      'United Kingdom', 1984, 1990),
  ('Level 9 Computing',       'level-9',               'United Kingdom', 1981, 1991),
  ('Core Design',             'core-design',           'United Kingdom', 1988, 2006),
  ('Domark',                  'domark',                'United Kingdom', 1984, 1996),
  ('Virgin Games',            'virgin-games',          'United Kingdom', 1983, NULL),
  ('Imagine Software',        'imagine-software',      'United Kingdom', 1982, 1984),
  ('Llamasoft',               'llamasoft',             'United Kingdom', 1982, NULL),
  ('Novagen Software',        'novagen',               'United Kingdom', 1984, 1994),
  ('Odin Computer Graphics',  'odin-computer-graphics','United Kingdom', 1985, 1989),
  ('Quicksilva',              'quicksilva',            'United Kingdom', 1980, 1986),
  ('Realtime Games Software', 'realtime-games',        'United Kingdom', 1984, 1993),
  ('Software Projects',       'software-projects',     'United Kingdom', 1983, 1989),
  ('Denton Designs',          'denton-designs',        'United Kingdom', 1984, NULL),
  ('Durell Software',         'durell-software',       'United Kingdom', 1983, 1991),
  ('Superior Software',       'superior-software',     'United Kingdom', 1982, NULL),
  ('Audiogenic',              'audiogenic',            'United Kingdom', 1979, 1999),
  ('21st Century Entertainment','21st-century',        'United Kingdom', 1992, 1997),
  ('Beyond Software',         'beyond-software',       'United Kingdom', 1984, 1986),
  ('CRL Group',               'crl-group',             'United Kingdom', 1983, 1991),
  ('Martech',                 'martech',               'United Kingdom', 1984, 1989),
  ('Mikro-Gen',               'mikro-gen',             'United Kingdom', 1981, 1987),
  ('Special FX Software',     'special-fx',            'United Kingdom', 1986, 1992),
  ('Alligata Software',       'alligata',              'United Kingdom', 1983, 1989),
  ('Interceptor Micros',      'interceptor-micros',    'United Kingdom', 1983, 1989),
  ('Players Software',        'players-software',      'United Kingdom', 1985, 1990),
  ('Bubble Bus Software',     'bubble-bus',            'United Kingdom', 1984, 1989),
  ('English Software',        'english-software',      'United Kingdom', 1982, 1987),
  ('Tynesoft',                'tynesoft',              'United Kingdom', 1983, 1991),
  ('Psionic Systems',         'psionic-systems',       'United Kingdom', NULL, NULL),
  ('Millennium Interactive',  'millennium-interactive','United Kingdom', 1987, 1997),
  ('Renegade Software',       'renegade-software',     'United Kingdom', 1990, 1996),
  ('Microprose Software',     'microprose',            'United States',  1982, NULL),

  -- Germany
  ('Rainbow Arts',            'rainbow-arts',          'Germany',        1984, 1996),
  ('Factor 5',                'factor-5',              'Germany',        1987, NULL),
  ('Blue Byte',               'blue-byte',             'Germany',        1988, NULL),
  ('Thalion Software',        'thalion',               'Germany',        1988, 1994),
  ('reLINE Software',         'reline-software',       'Germany',        1985, 1996),
  ('Kingsoft',                'kingsoft',              'Germany',        1984, 1996),
  ('Ariolasoft',              'ariolasoft',            'Germany',        1983, 1989),
  ('Golden Goblins',          'golden-goblins',        'Germany',        NULL, NULL),
  ('Softgold',                'softgold',              'Germany',        1987, 1997),
  ('Max Design',              'max-design',            'Austria',        1991, 2004),
  ('neo Software',            'neo-software',          'Austria',        1993, NULL),

  -- France
  ('Titus Interactive',       'titus',                 'France',         1985, 2005),
  ('Infogrames',              'infogrames',            'France',         1983, NULL),
  ('Ubi Soft',                'ubi-soft',              'France',         1986, NULL),
  ('Loriciel',                'loriciel',              'France',         1983, 1994),
  ('Ere Informatique',        'ere-informatique',      'France',         1983, 1991),
  ('Coktel Vision',           'coktel-vision',         'France',         1984, 2005),
  ('Silmarils',               'silmarils',             'France',         1987, 2003),
  ('Delphine Software',       'delphine-software',     'France',         1988, 2004),
  ('Palace Software France',  'palace-france',         'France',         NULL, NULL),
  ('Lankhor',                 'lankhor',               'France',         1987, 2001),

  -- Nordics
  ('Digital Illusions CE',    'digital-illusions-ce',  'Sweden',         1992, NULL),
  ('Unique Development Studios','uds',                 'Sweden',         1993, 2004),
  ('Starbreeze Studios',      'starbreeze',            'Sweden',         1998, NULL),
  ('Massive Entertainment',   'massive-entertainment', 'Sweden',         1997, NULL),
  ('Daydream Software',       'daydream-software',     'Sweden',         1994, 2002),
  ('Funcom',                  'funcom',                'Norway',         1993, NULL),
  ('Innerloop Studios',       'innerloop-studios',     'Norway',         1994, 2008),
  ('Housemarque',             'housemarque',           'Finland',        1995, NULL),
  ('Bloodhouse',              'bloodhouse',            'Finland',        1993, 1995),
  ('Terramarque',             'terramarque',           'Finland',        1993, 1995),
  ('IO Interactive',          'io-interactive',        'Denmark',        1998, NULL),
  ('Deadline Games',          'deadline-games',        'Denmark',        1996, 2009),

  -- United States
  ('Epyx',                    'epyx',                  'United States',  1978, 1993),
  ('Activision',              'activision',            'United States',  1979, NULL),
  ('Broderbund',              'broderbund',            'United States',  1980, 1998),
  ('Infocom',                 'infocom',               'United States',  1979, 1989),
  ('Origin Systems',          'origin-systems',        'United States',  1983, 2004),
  ('Sierra On-Line',          'sierra-on-line',        'United States',  1979, NULL),
  ('Lucasfilm Games',         'lucasfilm-games',       'United States',  1982, NULL),
  ('Interplay Productions',   'interplay',             'United States',  1983, NULL),
  ('Cinemaware',              'cinemaware',            'United States',  1985, 1991),
  ('Strategic Simulations',   'ssi',                   'United States',  1979, 1994),
  ('Access Software',         'access-software',       'United States',  1982, 2004),
  ('Accolade',                'accolade',              'United States',  1984, 1999),
  ('Datasoft',                'datasoft',              'United States',  1980, 1988),
  ('First Star Software',     'first-star-software',   'United States',  1982, NULL),
  ('Synapse Software',        'synapse-software',      'United States',  1981, 1985),
  ('MicroIllusions',          'microillusions',        'United States',  1986, 1992),
  ('New World Computing',     'new-world-computing',   'United States',  1984, 2003),
  ('Westwood Studios',        'westwood-studios',      'United States',  1985, 2003),
  ('Maxis',                   'maxis',                 'United States',  1987, NULL),
  ('Spectrum HoloByte',       'spectrum-holobyte',     'United States',  1983, 1998),
  ('Mindscape',               'mindscape',             'United States',  1983, 2011),
  ('Mediagenic',              'mediagenic',            'United States',  1988, 1992),

  -- Japan, mostly for the MSX shelf
  ('Hudson Soft',             'hudson-soft',           'Japan',          1973, 2012),
  ('Compile',                 'compile',               'Japan',          1982, 2003),
  ('T&E Soft',                't-and-e-soft',          'Japan',          1982, NULL),
  ('Micro Cabin',             'micro-cabin',           'Japan',          1982, NULL),
  ('ASCII Corporation',       'ascii-corporation',     'Japan',          1977, NULL),
  ('Nihon Falcom',            'nihon-falcom',          'Japan',          1981, NULL),
  ('Namco',                   'namco',                 'Japan',          1955, NULL),
  ('Taito',                   'taito',                 'Japan',          1953, NULL),
  ('Capcom',                  'capcom',                'Japan',          1979, NULL),
  ('Sega',                    'sega',                  'Japan',          1960, NULL),
  ('Nintendo',                'nintendo',              'Japan',          1889, NULL),

  -- Australia
  ('Beam Software',           'beam-software',         'Australia',      1980, 1999);


-- ---------------------------------------------------------------------------
-- Hardware
-- ---------------------------------------------------------------------------

-- Hardware taxonomy. Peripherals are the point, so the list leads with them
-- rather than treating everything as an afterthought on "computer".
-- ---------------------------------------------------------------------------

-- Amiga interfaces, in the Amiga Hardware Database's own vocabulary.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'z1' AS code, 'Zorro I' AS name, 10 AS sort_order UNION ALL
  SELECT 'z2', 'Zorro II', 20 UNION ALL
  SELECT 'z3', 'Zorro III', 30 UNION ALL
  SELECT 'vid', 'Video slot', 40 UNION ALL
  SELECT 'isa', 'ISA slot', 50 UNION ALL
  SELECT 'cpu', 'CPU slot', 60 UNION ALL
  SELECT '68k', '68000 socket', 70 UNION ALL
  SELECT 'side', 'Side slot', 80 UNION ALL
  SELECT 'trap', 'Trapdoor slot', 90 UNION ALL
  SELECT 'clk', 'Clock port', 100 UNION ALL
  SELECT 'pcm', 'PCMCIA slot', 110 UNION ALL
  SELECT 'agnus', 'Agnus socket', 120 UNION ALL
  SELECT 'denise', 'Denise socket', 130 UNION ALL
  SELECT 'lisa', 'Lisa socket', 140 UNION ALL
  SELECT 'cia', 'CIA socket', 150 UNION ALL
  SELECT 'paula', 'Paula socket', 160 UNION ALL
  SELECT 'kick', 'Kickstart socket', 170 UNION ALL
  SELECT 'rgb', 'RGB port', 180 UNION ALL
  SELECT 'par', 'Parallel port', 190 UNION ALL
  SELECT 'ser', 'Serial port', 200 UNION ALL
  SELECT 'misc', 'Miscellaneous', 900
) v WHERE p.slug IN ('amiga', 'cd32', 'cdtv');

-- What an expansion adds. Same vocabulary, applies to any machine.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'feature', NULL, v.code, v.name, v.sort_order FROM (
  SELECT 'cpu' AS code, 'Processor' AS name, 10 AS sort_order UNION ALL
  SELECT 'fpu', 'FPU', 20 UNION ALL
  SELECT 'ram', 'Memory', 30 UNION ALL
  SELECT 'scsi', 'SCSI controller', 40 UNION ALL
  SELECT 'ide', 'IDE controller', 50 UNION ALL
  SELECT 'mfm', 'ST-506 / ST-412 controller', 60 UNION ALL
  SELECT 'sasi', 'SASI controller', 70 UNION ALL
  SELECT 'cd', 'CD-ROM controller', 80 UNION ALL
  SELECT 'floppy', 'Floppy controller', 90 UNION ALL
  SELECT 'ser', 'Serial port', 100 UNION ALL
  SELECT 'par', 'Parallel port', 110 UNION ALL
  SELECT 'gpib', 'GPIB port', 120 UNION ALL
  SELECT 'usb', 'USB port', 130 UNION ALL
  SELECT 'modem', 'Modem', 140 UNION ALL
  SELECT 'isdn', 'ISDN', 150 UNION ALL
  SELECT 'eth', 'Ethernet', 160 UNION ALL
  SELECT 'arcnet', 'Arcnet', 170 UNION ALL
  SELECT 'gfx', 'Graphics', 180 UNION ALL
  SELECT 'snd', 'Sound', 190 UNION ALL
  SELECT 'rtc', 'Real-time clock', 200
) v;

-- Other machines, so hardware is not an Amiga-only feature.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'cart' AS code, 'Cartridge port' AS name, 10 AS sort_order UNION ALL
  SELECT 'user', 'User port', 20 UNION ALL
  SELECT 'serial', 'Serial (IEC) port', 30 UNION ALL
  SELECT 'tape', 'Cassette port', 40 UNION ALL
  SELECT 'joy', 'Control port', 50
) v WHERE p.slug IN ('c64', 'vic-20', 'plus4', 'pet', 'c128');

INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'cart' AS code, 'Cartridge slot' AS name, 10 AS sort_order UNION ALL
  SELECT 'joy', 'Joystick port', 20
) v WHERE p.slug IN ('msx', 'master-system', 'mega-drive', 'nes', 'snes');

-- ---------------------------------------------------------------------------
-- The PC, where the bus is the thing that matters.
--
-- A card is defined by what it plugs into - ISA, VLB, PCI, AGP - far more than
-- by what it is called. Without this a motherboard or an expansion card has
-- nothing to normalise against, and "16-bit ISA", "ISA 16", "AT bus" all end up
-- as separate spellings of one slot.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'isa8'   AS code, 'ISA, 8-bit'          AS name,  10 AS sort_order UNION ALL
  SELECT 'isa16',         'ISA, 16-bit',                   20 UNION ALL
  SELECT 'eisa',          'EISA',                          30 UNION ALL
  SELECT 'mca',           'MCA (Micro Channel)',           40 UNION ALL
  SELECT 'vlb',           'VESA Local Bus',                50 UNION ALL
  SELECT 'pci',           'PCI',                           60 UNION ALL
  SELECT 'agp',           'AGP',                           70 UNION ALL
  SELECT 'pcie',          'PCI Express',                   80 UNION ALL
  SELECT 'ide',           'IDE / ATA header',             100 UNION ALL
  SELECT 'floppy',        'Floppy header',                110 UNION ALL
  SELECT 'scsi',          'SCSI',                         120 UNION ALL
  SELECT 'ps2',           'PS/2 port',                    130 UNION ALL
  SELECT 'serial',        'Serial port',                  140 UNION ALL
  SELECT 'parallel',      'Parallel port',                150 UNION ALL
  SELECT 'gameport',      'Game port',                    160 UNION ALL
  SELECT 'usb',           'USB',                          170 UNION ALL
  SELECT 'simm30',        '30-pin SIMM socket',           200 UNION ALL
  SELECT 'simm72',        '72-pin SIMM socket',           210 UNION ALL
  SELECT 'dimm',          'DIMM socket',                  220 UNION ALL
  SELECT 'cpusocket',     'CPU socket',                   230 UNION ALL
  SELECT 'cpuslot',       'CPU slot',                     240 UNION ALL
  SELECT 'misc',          'Miscellaneous',                900
) v WHERE p.slug IN ('pc');

-- CPU sockets and slots, kept apart from the bus because a board is described
-- by both: an ISA card fits a slot, a processor fits a socket, and conflating
-- them makes "what will this take?" unanswerable.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'socket', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'dip'      AS code, 'DIP (8086/286)'    AS name,  10 AS sort_order UNION ALL
  SELECT 'plcc',           'PLCC',                         20 UNION ALL
  SELECT 'socket3',        'Socket 3 (486)',               30 UNION ALL
  SELECT 'socket4',        'Socket 4',                     40 UNION ALL
  SELECT 'socket5',        'Socket 5',                     50 UNION ALL
  SELECT 'socket7',        'Socket 7',                     60 UNION ALL
  SELECT 'ssocket7',       'Super Socket 7',               70 UNION ALL
  SELECT 'socket8',        'Socket 8 (Pentium Pro)',       80 UNION ALL
  SELECT 'slot1',          'Slot 1',                       90 UNION ALL
  SELECT 'slota',          'Slot A',                      100 UNION ALL
  SELECT 'socket370',      'Socket 370',                  110 UNION ALL
  SELECT 'socketa',        'Socket A (462)',              120 UNION ALL
  SELECT 'socket423',      'Socket 423',                  130 UNION ALL
  SELECT 'socket478',      'Socket 478',                  140
) v WHERE p.slug IN ('pc');

-- Form factors, which decide whether a board will physically go in a case.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'formfactor', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'at'       AS code, 'AT'           AS name, 10 AS sort_order UNION ALL
  SELECT 'babyat',         'Baby AT',              20 UNION ALL
  SELECT 'atx',            'ATX',                  30 UNION ALL
  SELECT 'matx',           'microATX',             40 UNION ALL
  SELECT 'flexatx',        'FlexATX',              50 UNION ALL
  SELECT 'nlx',            'NLX',                  60 UNION ALL
  SELECT 'lpx',            'LPX',                  70
) v WHERE p.slug IN ('pc');


-- ---------------------------------------------------------------------------
-- The machine, and separately what it boots.
--
-- A motherboard is PC hardware, not "MS-DOS hardware". Listing the operating
-- systems as platforms made the hardware side of the catalogue read wrongly and
-- meant a 486 board had to pick one of three machines that were all the same
-- machine.
-- ---------------------------------------------------------------------------

-- Generated from starter-data/environments.json.
--
-- The two have to agree: a fresh install loads this file, and the first template
-- sync reads the JSON. If they disagree the sync reports work to do on a brand-new
-- instance, which is how tests/templates.php noticed the last time they drifted.

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'Workbench 1.x' AS name, 'wb1' AS slug, 10 AS sort_order UNION ALL
  SELECT 'Workbench 2.x', 'wb2', 20 UNION ALL
  SELECT 'Workbench 3.x', 'wb3', 30 UNION ALL
  SELECT 'AmigaOS 4', 'os4', 40
) v ON p.slug = 'amiga';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'CP/M 2.2' AS name, 'cpm22' AS slug, 10 AS sort_order UNION ALL
  SELECT 'AMSDOS', 'amsdos', 20
) v ON p.slug = 'amstrad-cpc';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'Apple DOS 3.3' AS name, 'apple-dos33' AS slug, 10 AS sort_order UNION ALL
  SELECT 'ProDOS', 'prodos', 20
) v ON p.slug = 'apple-ii';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'RISC OS' AS name, 'riscos' AS slug, 10 AS sort_order
) v ON p.slug = 'archimedes';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'TOS' AS name, 'tos' AS slug, 10 AS sort_order UNION ALL
  SELECT 'GEM', 'gem', 20 UNION ALL
  SELECT 'MagiC', 'magic', 30
) v ON p.slug = 'atari-st';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'Commodore BASIC' AS name, 'c64-basic' AS slug, 10 AS sort_order UNION ALL
  SELECT 'GEOS', 'geos64', 20
) v ON p.slug = 'c64';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'System 6 and earlier' AS name, 'mac-system' AS slug, 10 AS sort_order UNION ALL
  SELECT 'System 7', 'mac-system7', 20 UNION ALL
  SELECT 'Mac OS 8 and 9', 'mac-os8', 30
) v ON p.slug = 'mac-68k';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'MSX-DOS' AS name, 'cpm-msx' AS slug, 10 AS sort_order UNION ALL
  SELECT 'MSX BASIC', 'msx-basic', 20
) v ON p.slug = 'msx';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'MS-DOS' AS name, 'ms-dos' AS slug, 10 AS sort_order UNION ALL
  SELECT 'PC DOS', 'pc-dos', 15 UNION ALL
  SELECT 'Windows 3.x', 'win3x', 20 UNION ALL
  SELECT 'Windows 9x', 'win9x', 30 UNION ALL
  SELECT 'Windows NT/2000', 'winnt', 40 UNION ALL
  SELECT 'Windows XP', 'winxp', 45 UNION ALL
  SELECT 'OS/2', 'os2', 50 UNION ALL
  SELECT 'Linux', 'linux-pc', 60 UNION ALL
  SELECT 'CP/M-86', 'cpm86', 70
) v ON p.slug = 'pc';

INSERT IGNORE INTO operating_systems (platform_id, name, slug, sort_order)
SELECT p.id, v.name, v.slug, v.sort_order FROM platforms p JOIN (
  SELECT 'Sinclair BASIC' AS name, 'spectrum-basic' AS slug, 10 AS sort_order
) v ON p.slug = 'zx-spectrum';

-- Consoles have none, deliberately: a cartridge does not run on an operating
-- system you chose, and offering the field would be noise on every entry.

-- ---------------------------------------------------------------------------
-- What kind of thing an entry is.
--
-- Platform-independent on purpose. An adapter is an adapter whether it plugs
-- into an Amiga or a PC; what differs is the connector, and that is already
-- described per machine in hardware_vocab. Keeping these shared is why there
-- are thirty rows here rather than one set per machine.
--
-- Set platform_id only where a kind really does belong to one machine.
-- ---------------------------------------------------------------------------
-- applies_to: which machine classes a kind belongs on, empty meaning all of them.
-- It is what stops a Game Boy branch acquiring disk controllers and antivirus tools.
INSERT IGNORE INTO categories (id, domain, parent_id, name, slug, sort_order, applies_to) VALUES
  -- Software. Games are one kind among several, not a synonym for software.
      (1, 'software', NULL, 'Games', 'games', 10, ''),
      (2, 'software', NULL, 'Applications', 'applications', 20, 'computer'),
      (3, 'software', 2, 'Graphics and CAD', 'graphics-cad', 21, 'computer'),
      (4, 'software', 3, 'Paint', 'paint', 22, 'computer'),
      (5, 'software', 3, '3D and rendering', 'rendering', 23, ''),
      (6, 'software', 3, 'CAD', 'cad', 24, ''),
      (7, 'software', 3, 'Animation', 'animation', 25, ''),
      (8, 'software', 3, 'Video and genlock', 'video-genlock', 26, ''),
      (9, 'software', 2, 'Productivity', 'productivity', 30, 'computer'),
      (10, 'software', 9, 'Word processor', 'word-processor', 31, 'computer'),
      (11, 'software', 9, 'Spreadsheet', 'spreadsheet', 32, 'computer'),
      (12, 'software', 9, 'Database', 'database', 33, 'computer'),
      (13, 'software', 9, 'Desktop publishing', 'dtp', 34, 'computer'),
      (14, 'software', 9, 'Accounting', 'accounting', 35, ''),
      (15, 'software', 9, 'Comms and terminal', 'comms', 36, ''),
      (16, 'software', 2, 'Music and audio', 'music-audio', 40, 'computer'),
      (17, 'software', 16, 'Tracker', 'tracker', 41, 'computer'),
      (18, 'software', 16, 'Sample editor', 'sample-editor', 42, 'computer'),
      (19, 'software', 16, 'Music disk', 'music-disk', 43, 'computer'),
      (20, 'software', 2, 'Development', 'development', 50, 'computer'),
      (21, 'software', 20, 'Assembler', 'assembler', 51, 'computer'),
      (22, 'software', 20, 'Compiler', 'compiler', 52, 'computer'),
      (23, 'software', 20, 'BASIC', 'basic', 53, 'computer'),
      (24, 'software', 20, 'Game creation', 'game-creation', 54, 'computer'),
      (25, 'software', NULL, 'Demoscene', 'demoscene', 60, 'computer'),
      (26, 'software', 25, 'Demo', 'demo', 61, 'computer'),
      (27, 'software', 25, 'Intro and cracktro', 'intro', 62, ''),
      (28, 'software', 25, 'Diskmag', 'diskmag', 63, 'computer'),
      (29, 'software', NULL, 'Utilities', 'utilities', 70, 'computer'),
      (30, 'software', 29, 'Disk tools', 'disk-tools', 71, 'computer'),
      (31, 'software', 29, 'Backup and copier', 'backup', 72, ''),
      (32, 'software', 29, 'Virus tools', 'virus-tools', 73, 'computer'),
      (33, 'software', NULL, 'Operating system', 'operating-system', 80, 'computer'),
      (34, 'software', NULL, 'Other software', 'other-software', 90, 'computer,console,handheld'),

  -- Hardware
      (50, 'hardware', NULL, 'Computers', 'computers', 10, 'computer'),
  -- Siblings, not children. A console is not a kind of computer, and filing it
  -- as one made the tree say something untrue.
      (51, 'hardware', NULL, 'Consoles', 'console', 11, 'console'),
      (52, 'hardware', NULL, 'Handhelds', 'handheld', 12, 'handheld'),
      (53, 'hardware', NULL, 'Peripherals', 'peripherals', 20, ''),
      (54, 'hardware', 53, 'Adapters', 'adapters', 21, 'computer'),
      (55, 'hardware', 54, 'Network adapters', 'network-adapters', 22, 'computer'),
      (56, 'hardware', 53, 'Storage', 'storage', 23, 'computer'),
      (57, 'hardware', 53, 'Controllers', 'controllers', 24, 'computer,console,handheld'),
      (58, 'hardware', 53, 'Displays', 'displays', 25, 'computer'),
      (59, 'hardware', 53, 'Audio', 'audio', 26, 'computer'),
      (60, 'hardware', 53, 'Printers', 'printers', 27, 'computer'),
      (61, 'hardware', NULL, 'Expansions', 'expansions', 30, 'computer'),
      (62, 'hardware', 61, 'Accelerator', 'accelerator', 31, 'computer'),
      (63, 'hardware', 61, 'Memory', 'memory', 32, 'computer'),
      (64, 'hardware', 61, 'Graphics card', 'graphics-card', 33, 'computer'),
      (65, 'hardware', 61, 'Disk controller', 'disk-controller', 34, 'computer'),
      (66, 'hardware', 61, 'Sound card', 'sound-card', 35, 'computer'),
      (67, 'hardware', NULL, 'Parts and spares', 'parts', 40, ''),
      (68, 'hardware', 67, 'Power supply', 'power-supply', 41, 'computer,console'),
      (69, 'hardware', 67, 'Cables', 'cables', 42, 'computer,console'),
      (70, 'hardware', 67, 'Chips', 'chips', 43, 'computer'),
      (71, 'hardware', NULL, 'Blank media', 'blank-media', 50, 'computer'),
      (72, 'hardware', NULL, 'Other hardware', 'other-hardware', 90, ''),
  (73, 'hardware', 53, 'Memory cards', 'memory-cards', 28, 'console'),
  (74, 'hardware', 53, 'Flash carts', 'flash-carts', 29, 'console,handheld'),
  (75, 'hardware', NULL, 'Cartridges', 'cartridges', 30, 'console,handheld');

-- Paths, three passes for a tree three deep.
UPDATE categories SET path = CONCAT('/', id, '/'), depth = 0 WHERE parent_id IS NULL;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 1 WHERE p.depth = 0;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 2 WHERE p.depth = 1;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 3 WHERE p.depth = 2;

-- ---------------------------------------------------------------------------
-- Genres, which describe games and nothing else.
--
-- A word processor is not a genre of software - it is what the software is,
-- and that lives in the tree above. Mixing the two put "Compiler" next to
-- "Platformer" on the Genres page and made neither idea legible.
-- ---------------------------------------------------------------------------
-- Genres are children of Games in the category tree, not rows in a table of their
-- own. The same mechanism gives Applications › Music and audio › Tracker, so
-- "Games › Beat 'em up" needs no new concept - and a word processor is filed under
-- Applications › Productivity by exactly the same route.
INSERT IGNORE INTO categories (parent_id, name, slug, domain, role, sort_order)
SELECT c.id, v.name, v.slug, 'software', 'other', v.sort_order FROM categories c JOIN (
  SELECT 'Action'              AS name, 'action'            AS slug,  10 AS sort_order UNION ALL
  SELECT 'Platformer',               'platformer',                    20 UNION ALL
  SELECT 'Shoot \'em up',            'shoot-em-up',                   30 UNION ALL
  SELECT 'Beat \'em up',             'beat-em-up',                    40 UNION ALL
  SELECT 'Fighting',                 'fighting',                      50 UNION ALL
  SELECT 'Run and gun',              'run-and-gun',                   60 UNION ALL
  SELECT 'Role-playing',             'role-playing',                  70 UNION ALL
  SELECT 'Adventure',                'adventure',                     80 UNION ALL
  SELECT 'Point and click',          'point-and-click',               90 UNION ALL
  SELECT 'Text adventure',           'text-adventure',               100 UNION ALL
  SELECT 'Strategy',                 'strategy',                     110 UNION ALL
  SELECT 'Management and tycoon',    'management',                   120 UNION ALL
  SELECT 'Simulation',               'simulation',                   130 UNION ALL
  SELECT 'Flight simulator',         'flight-sim',                   140 UNION ALL
  SELECT 'Racing',                   'racing',                       150 UNION ALL
  SELECT 'Sports',                   'sports',                       160 UNION ALL
  SELECT 'Puzzle',                   'puzzle',                       170 UNION ALL
  SELECT 'Pinball',                  'pinball',                      180 UNION ALL
  SELECT 'Board and card',           'board-card',                   190 UNION ALL
  SELECT 'Maze',                     'maze',                         200 UNION ALL
  SELECT 'Compilation',              'compilation',                  210
) AS v ON c.slug = 'games';

-- Paths again, now that the tree has changed shape.
UPDATE categories SET path = CONCAT('/', id, '/'), depth = 0 WHERE parent_id IS NULL;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 1 WHERE p.depth = 0;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 2 WHERE p.depth = 1;
UPDATE categories c JOIN categories p ON p.id = c.parent_id SET c.path = CONCAT(p.path, c.id, '/'), c.depth = 3 WHERE p.depth = 2;



-- ---------------------------------------------------------------------------
-- What each model will actually take.
--
-- The point of recording models at all. Offering a C64 owner a PCI slot is not
-- untidy, it invites a wrong entry - and a catalogue is only worth keeping if
-- what it says is true.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Expansion vocabulary for the remaining families.
--
-- Without this a model's slots cannot be recorded, because model_slots joins on
-- a vocabulary code - so an Atari ST could be listed but never say what it
-- takes, which is the only reason to list it.
-- ---------------------------------------------------------------------------

-- Atari ST. The cartridge and DMA ports are common to the family; the internal
-- bus, VME and the Falcon's direct slot appear only on particular machines,
-- which is exactly the distinction model_slots exists to record.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'cart'  AS code, 'Cartridge port'          AS name, 10 AS sort_order UNION ALL
  SELECT 'acsi',        'DMA / ACSI port',                20 UNION ALL
  SELECT 'midi',        'MIDI in and out',                30 UNION ALL
  SELECT 'stbus',       'Internal expansion bus',         40 UNION ALL
  SELECT 'vme',         'VME slot',                       50 UNION ALL
  SELECT 'pds',         'Processor direct slot',          60 UNION ALL
  SELECT 'floppy',      'Floppy port',                    70 UNION ALL
  SELECT 'joy',         'Joystick port',                  80 UNION ALL
  SELECT 'ser',         'Serial port',                    90 UNION ALL
  SELECT 'par',         'Parallel port',                 100 UNION ALL
  SELECT 'simm',        'SIMM socket',                   110 UNION ALL
  SELECT 'misc',        'Miscellaneous',                 900
) v WHERE p.slug = 'atari-st';

-- Atari 8-bit
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'cart' AS code, 'Cartridge slot' AS name, 10 AS sort_order UNION ALL
  SELECT 'sio',        'SIO bus',                20 UNION ALL
  SELECT 'pbi',        'Parallel Bus Interface', 30 UNION ALL
  SELECT 'eci',        'Enhanced Cartridge Interface', 40 UNION ALL
  SELECT 'joy',        'Joystick port',          50 UNION ALL
  SELECT 'misc',       'Miscellaneous',         900
) v WHERE p.slug = 'atari-8bit';

-- Sinclair
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'edge' AS code, 'Rear edge connector' AS name, 10 AS sort_order UNION ALL
  SELECT 'tape',       'Tape port',                    20 UNION ALL
  SELECT 'joy',        'Joystick port',                30 UNION ALL
  SELECT 'ay',         'Sound and MIDI',               40 UNION ALL
  SELECT 'misc',       'Miscellaneous',               900
) v WHERE p.slug IN ('zx-spectrum', 'zx81', 'sam-coupe');

-- Amstrad
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'edge' AS code, 'Expansion edge connector' AS name, 10 AS sort_order UNION ALL
  SELECT 'floppy',     'Floppy port',                       20 UNION ALL
  SELECT 'joy',        'Joystick port',                     30 UNION ALL
  SELECT 'printer',    'Printer port',                      40 UNION ALL
  SELECT 'misc',       'Miscellaneous',                    900
) v WHERE p.slug IN ('amstrad-cpc', 'amstrad-pcw');

-- Acorn. A podule is a podule whether it goes in a BBC or an Archimedes.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'podule' AS code, 'Podule slot' AS name, 10 AS sort_order UNION ALL
  SELECT 'edge',         'Rear expansion connector',  15 UNION ALL
  SELECT 'tube',         'Tube interface',      20 UNION ALL
  SELECT 'onemhz',       '1 MHz bus',           30 UNION ALL
  SELECT 'userport',     'User port',           40 UNION ALL
  SELECT 'econet',       'Econet',              50 UNION ALL
  SELECT 'misc',         'Miscellaneous',      900
) v WHERE p.slug IN ('bbc-micro', 'acorn-electron', 'archimedes', 'risc-pc');

-- Apple
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'aslot' AS code, 'Apple II expansion slot' AS name, 10 AS sort_order UNION ALL
  SELECT 'nubus',       'NuBus slot',                     20 UNION ALL
  SELECT 'pds',         'Processor direct slot',          30 UNION ALL
  SELECT 'scsi',        'SCSI',                           40 UNION ALL
  SELECT 'adb',         'Apple Desktop Bus',              50 UNION ALL
  SELECT 'simm',        'SIMM socket',                    60 UNION ALL
  SELECT 'misc',        'Miscellaneous',                 900
) v WHERE p.slug IN ('apple-ii', 'mac-68k');




-- ---------------------------------------------------------------------------
-- Consoles expand differently from computers, and from each other.
--
-- The question is rarely "which card" but "what can be bolted on": a Mega Drive
-- has a side port for the Mega-CD and a cartridge slot the 32X sits in; a Game
-- Boy has a link port; a PlayStation has memory card slots and a parallel port
-- the early boards dropped. Recording that is the same idea as Zorro on an
-- A2000, and just as easy to get wrong from memory.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, v.code, v.name, v.sort_order FROM platforms p JOIN (
  SELECT 'cart'  AS code, 'Cartridge slot'        AS name,  10 AS sort_order UNION ALL
  SELECT 'ctrl',        'Controller port',                  20 UNION ALL
  SELECT 'exp',         'Expansion port',                   30 UNION ALL
  SELECT 'cdport',      'CD unit connector',                40 UNION ALL
  SELECT 'link',        'Link cable port',                  50 UNION ALL
  SELECT 'memcard',     'Memory card slot',                 60 UNION ALL
  SELECT 'av',          'AV output',                        70 UNION ALL
  SELECT 'rf',          'RF output',                        80 UNION ALL
  SELECT 'passthru',    'Cartridge pass-through',           90 UNION ALL
  SELECT 'modem',       'Modem or network port',           100 UNION ALL
  SELECT 'psu',         'Power input',                     110 UNION ALL
  SELECT 'misc',        'Miscellaneous',                   900
) v WHERE p.slug IN (
  'nes','snes','n64','game-boy','gba','virtual-boy','sg-1000','master-system',
  'mega-drive','mega-cd','sega-32x','game-gear','saturn','dreamcast',
  'atari-2600','atari-5200','atari-7800','lynx','jaguar','pc-engine',
  'neo-geo','playstation','3do','cd-i','intellivision','colecovision','vectrex'
);










-- ---------------------------------------------------------------------------
-- One example of each shape, to copy from.
--
-- Not a catalogue. These exist to show what a filled-in model looks like so the
-- next one can be built by copying, and to be deleted once they have.
--
-- Whether something is a machine or a part is decided by its type: a computer
-- is a machine, an accelerator is a part. Nothing else records the difference.
-- ---------------------------------------------------------------------------
-- (A second seeded maker list used to sit here, duplicating the one above.)


INSERT IGNORE INTO hardware_models (vendor_id, platform_id, category_id, name, slug, year_from, fits_note, interface, notes, sort_order)
SELECT v.id, p.id, c.id, x.name, x.slug, x.yr, x.fits_note, x.iface, x.notes, x.so
  FROM (
  SELECT 'Amiga 500' AS name, 'amiga-500' AS slug, 1987 AS yr, NULL AS fits_note, NULL AS iface,
         'An example of a computer. Edit it, copy it, or remove it once you have your own.' AS notes,
         'commodore' AS ven, 'amiga' AS plat, 'computers' AS cat, 10 AS so UNION ALL
  SELECT 'Sega Master System', 'sms-console', 1985, NULL, NULL,
         'An example of a console. It records no storage, so that box never appears.',
         'sega', 'master-system', 'console', 20 UNION ALL
  SELECT 'Game Boy', 'game-boy-dmg', 1989, NULL, NULL,
         'An example of a handheld.', 'nintendo', 'game-boy', 'handheld', 30 UNION ALL
  SELECT 'Generic 486 PC', 'pc-486', 1991, NULL, NULL,
         'An example of a PC. Real board models are better recorded one at a time.',
         'various-vendor', 'pc', 'computers', 40 UNION ALL
  SELECT 'Blizzard 1230 IV', 'blizzard-1230-iv', 1994, 'A1200 only', 'trap',
         'An example of an expansion card. Its type is what makes it a part rather than a machine.',
         'commodore', 'amiga', 'accelerator', 50 UNION ALL
  SELECT 'Sound Blaster 16', 'sound-blaster-16', 1992, 'any ISA PC', 'isa16',
         'An example of a PC card.', 'creative', 'pc', 'sound-card', 60
) x
  -- Templates only: once a library has copied these, the same slug exists
  -- several times and an unqualified join would multiply every row by the
  -- number of libraries.
  JOIN platforms  p ON p.slug = x.plat AND p.library_id IS NULL
  JOIN categories c ON c.slug = x.cat
  LEFT JOIN companies v ON v.slug = x.ven AND v.library_id IS NULL;

-- The fields each one carries, with the value it left the factory with. A
-- machine that had no hard disk simply has no Storage field, which is what
-- makes the box disappear rather than sit there empty.
INSERT IGNORE INTO model_fields (model_id, label, default_value, hint, sort_order)
SELECT hm.id, f.label, f.val, f.hint, f.so FROM (
  SELECT 'amiga-500' AS model, 'Processor' AS label, 'text' AS kind, '68000 @ 7.16 MHz' AS val, NULL AS opts, 'third' AS width, NULL AS hint, 10 AS so UNION ALL
  SELECT 'amiga-500',        'Memory',    'text', '512 KB', NULL, 'third', 'chip RAM as shipped', 20 UNION ALL
  SELECT 'amiga-500',        'Video',    'text', 'OCS', NULL, 'third', NULL, 30 UNION ALL
  SELECT 'amiga-500',        'Storage',    'text', 'floppy', NULL, 'third', NULL, 40 UNION ALL
  SELECT 'amiga-500',        'Kickstart', 'select', '1.3', '1.2\n1.3\n2.0\n3.1', 'third', 'ROM revision fitted', 50 UNION ALL
  SELECT 'sms-console',      'Processor',    'text', 'Z80 @ 3.58 MHz', NULL, 'third', NULL, 10 UNION ALL
  SELECT 'sms-console',      'Memory',    'text', '8 KB', NULL, 'third', NULL, 20 UNION ALL
  SELECT 'sms-console',      'Video',    'text', 'VDP', NULL, 'third', NULL, 30 UNION ALL
  SELECT 'sms-console',      'Region',    'select', 'PAL', 'PAL\nNTSC\nNTSC-J', 'third', 'which region this one is', 40 UNION ALL
  SELECT 'game-boy-dmg',     'Processor',    'text', 'Sharp LR35902 @ 4.19 MHz', NULL, 'third', NULL, 10 UNION ALL
  SELECT 'game-boy-dmg',     'Memory',    'text', '8 KB', NULL, 'third', NULL, 20 UNION ALL
  SELECT 'game-boy-dmg',     'Screen',    'text', 'mono LCD, 160x144', NULL, 'third', NULL, 30 UNION ALL
  SELECT 'pc-486',           'Processor',    'text', '80486, 25 to 100 MHz', NULL, 'third', 'a range, because a clone is one', 10 UNION ALL
  SELECT 'pc-486',           'Memory',    'text', '4 to 32 MB', NULL, 'third', NULL, 20 UNION ALL
  SELECT 'pc-486',           'Video',    'text', 'VGA or SVGA', NULL, 'third', NULL, 30 UNION ALL
  SELECT 'pc-486',           'Storage',    'text', 'floppy, IDE', NULL, 'third', NULL, 40 UNION ALL
  SELECT 'blizzard-1230-iv', 'Processor',    'text', '68030 @ 50 MHz', NULL, 'third', NULL, 10 UNION ALL
  SELECT 'blizzard-1230-iv', 'Memory',    'text', 'one 72-pin SIMM, up to 128 MB', NULL, 'third', NULL, 20 UNION ALL
  SELECT 'blizzard-1230-iv', 'Provides',    'text', 'optional SCSI-II module', NULL, 'third', NULL, 30 UNION ALL
  SELECT 'sound-blaster-16', 'Provides',    'text', '16-bit audio, MIDI, joystick', NULL, 'third', NULL, 10 UNION ALL
  SELECT 'sound-blaster-16', 'Chipset',    'text', 'CT1745 mixer', NULL, 'third', NULL, 20
) f JOIN hardware_models hm ON hm.slug = f.model;

-- What each machine will take. Parts occupy a slot rather than having them.
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, s.qty, s.note FROM (
  SELECT 'amiga-500'    AS model, 'trap'  AS code, 1 AS qty, 'trapdoor, under the machine' AS note UNION ALL
  SELECT 'amiga-500',         'side',  1, 'left side expansion bus' UNION ALL
  SELECT 'amiga-500',         'cpu',   1, 'CPU socket'              UNION ALL
  SELECT 'sms-console',       'cart',  1, 'cartridge slot'          UNION ALL
  SELECT 'sms-console',       'ctrl',  2, 'controller ports'        UNION ALL
  SELECT 'game-boy-dmg',      'cart',  1, 'cartridge slot'          UNION ALL
  SELECT 'game-boy-dmg',      'link',  1, 'link cable port'         UNION ALL
  SELECT 'pc-486',            'isa16', 6, 'ISA'                     UNION ALL
  SELECT 'pc-486',            'vlb',   2, 'VESA local bus'
) s
  JOIN hardware_models hm ON hm.slug = s.model
  -- platform_id 0 is the "applies anywhere" sentinel, and a model may have no
  -- platform at all, so match either. But prefer the platform's own row when it
  -- has one: 'cpu' means "CPU slot" on an Amiga and "Processor" generally, and
  -- matching both attaches two slots that are not the same thing.
  JOIN hardware_vocab hv
    ON hv.code = s.code
   AND hv.platform_id IN (0, COALESCE(hm.platform_id, 0))
   AND (hv.platform_id <> 0
        OR NOT EXISTS (SELECT 1 FROM hardware_vocab hv2
                        WHERE hv2.code = s.code
                          AND hv2.platform_id = COALESCE(hm.platform_id, 0)));


-- ---------------------------------------------------------------------------
-- What kind of machine each platform is.
--
-- What kind of machine each platform holds used to be set here, on the platform.
-- It is read from the machine models now, so a platform with no models yet
-- reports no kind - which is true, and better than the old fallback of "anything
-- unnamed is a computer" that would have filed the Dreamcast wrongly in silence.

-- ---------------------------------------------------------------------------
-- Which hardware categories hold machines, and which hold peripherals.
--
-- This used to be a list of three slugs in PHP, so the tree lived in the
-- database while the meaning of it lived in code. It decides what the entry
-- form asks for and what can be fitted to what, so it belongs with the tree.
-- ---------------------------------------------------------------------------
UPDATE categories SET role = 'machine'
 WHERE domain = 'hardware' AND slug IN ('computers', 'console', 'handheld');

UPDATE categories SET role = 'peripheral'
 WHERE domain = 'hardware' AND slug IN (
   'peripherals', 'adapters', 'network-adapters', 'storage', 'controllers',
   'displays', 'audio', 'printers',
   'expansions', 'accelerator', 'memory', 'graphics-card', 'disk-controller',
   'sound-card'
 );

-- Cables, chips, power supplies and blank media are real things you own, but
-- nothing is fitted to them and they are not fitted to anything.
UPDATE categories SET role = 'other'
 WHERE domain = 'hardware' AND slug IN
   ('parts', 'power-supply', 'cables', 'chips', 'blank-media');

-- ---------------------------------------------------------------------------
-- The Zorro machines, and a card that fits all of them.
--
-- Added because every earlier example fitted exactly one machine, which made
-- the compatibility set look like a single choice with extra steps. A BigRAM2008
-- is autoconfiguring Zorro II memory: it works in an A2000, an A3000 and an
-- A4000, and that is the ordinary case rather than the exception.
-- ---------------------------------------------------------------------------



INSERT IGNORE INTO hardware_models
  (vendor_id, platform_id, category_id, name, slug, year_from, interface, notes, sort_order)
SELECT v.id, p.id, c.id, x.name, x.slug, x.yr, x.iface, x.notes, x.so
  FROM (
    SELECT 'Amiga 2000' AS name, 'amiga-2000' AS slug, 1987 AS yr, NULL AS iface,
           'The desktop Amiga with Zorro II slots. The first one an expansion card was designed for.' AS notes,
           20 AS so, 'commodore' AS mk, 'amiga' AS pl, 'computers' AS ct UNION ALL
    SELECT 'Amiga 3000', 'amiga-3000', 1990, NULL,
           '32-bit Zorro III, SCSI on the board.', 30, 'commodore', 'amiga', 'computers' UNION ALL
    SELECT 'Amiga 4000', 'amiga-4000', 1992, NULL,
           'AGA and Zorro III. Shipped with a 68040 or a 68EC030 depending on the model.',
           40, 'commodore', 'amiga', 'computers' UNION ALL
    SELECT 'BigRAM 2008', 'bigram-2008', 1992, 'z2',
           'Zorro II memory card. Autoconfiguring, so it works in any Zorro machine rather than one model. The 2008 is a model number, not a year.',
           30, 'waw-elektronik', 'amiga', 'memory' UNION ALL
    -- A card that is still made, which is why it is here: a catalogue of retro
    -- hardware is not a catalogue of dead hardware, and the entry has to hold a
    -- graphics card that also does Ethernet and USB without needing three rows.
    SELECT 'MNT ZZ9000', 'zz9000', 2019, 'z2',
           'Graphics, Ethernet and USB on one Zorro card, built on a Xilinx Zynq XC7Z020 - an FPGA and two ARM cores rather than a fixed graphics chip, so what it does is decided by firmware. Successor to the VA2000.',
           50, 'mnt-research', 'amiga', 'graphics-card'
  ) x
  JOIN companies  v ON v.slug = x.mk AND v.library_id IS NULL
  JOIN platforms  p ON p.slug = x.pl AND p.library_id IS NULL
  JOIN categories c ON c.slug = x.ct;

INSERT IGNORE INTO model_fields (model_id, label, default_value, hint, sort_order)
SELECT hm.id, f.label, f.val, NULL, f.so FROM (
  SELECT 'amiga-2000' AS model, 'Processor' AS label, '68000 @ 7.16 MHz' AS val, 10 AS so UNION ALL
  SELECT 'amiga-2000', 'Memory',    '1 MB chip', 20 UNION ALL
  SELECT 'amiga-2000', 'Expansion', 'Zorro II, plus ISA and a CPU slot', 30 UNION ALL
  SELECT 'amiga-2000', 'Storage',   'floppy', 40 UNION ALL
  SELECT 'amiga-3000', 'Processor', '68030 @ 16 or 25 MHz', 10 UNION ALL
  SELECT 'amiga-3000', 'Memory',    '2 MB', 20 UNION ALL
  SELECT 'amiga-3000', 'Expansion', 'Zorro III', 30 UNION ALL
  SELECT 'amiga-3000', 'Storage',   'floppy, SCSI', 40 UNION ALL
  SELECT 'amiga-4000', 'Processor', '68040 @ 25 MHz, or 68EC030', 10 UNION ALL
  SELECT 'amiga-4000', 'Memory',    '2 MB chip, 4 MB fast', 20 UNION ALL
  SELECT 'amiga-4000', 'Expansion', 'Zorro III', 30 UNION ALL
  SELECT 'amiga-4000', 'Storage',   'floppy, IDE', 40 UNION ALL
  SELECT 'bigram-2008', 'Memory',       '8 MB soldered to the board, sixteen 1M x 4 chips', 10 UNION ALL
  SELECT 'bigram-2008', 'Waitstates',   'none', 20 UNION ALL
  SELECT 'bigram-2008', 'Configurable', '2, 4 or 6 MB, to avoid clashing with another card', 30 UNION ALL
  SELECT 'bigram-2008', 'Interface',    'Zorro II', 40 UNION ALL
  SELECT 'bigram-2008', 'Autoconfig ID','257 / 10', 50 UNION ALL
  SELECT 'zz9000', 'Chip',       'Xilinx Zynq XC7Z020: 7-series FPGA plus 2x ARM Cortex-A9 @ 666 MHz', 10 UNION ALL
  SELECT 'zz9000', 'Memory',     '1 GB DDR3', 20 UNION ALL
  SELECT 'zz9000', 'Interface',  'Zorro II or Zorro III', 30 UNION ALL
  SELECT 'zz9000', 'Resolution', 'up to 1920x1080 - 16-bit at FHD, up to 32-bit below it', 40 UNION ALL
  SELECT 'zz9000', 'Colour',     '8-bit chunky, 16-bit or 32-bit', 50 UNION ALL
  SELECT 'zz9000', 'Video in',   'Amiga native passthrough with AGA scandoubler and flicker-fixer (ZZ9000CX)', 60 UNION ALL
  SELECT 'zz9000', 'Network',    'Ethernet, SANA-II driver', 70 UNION ALL
  SELECT 'zz9000', 'USB',        'mass storage, mountable as an Amiga drive', 80 UNION ALL
  SELECT 'zz9000', 'Firmware',   'BOOT.bin on a FAT32 MicroSD card', 90 UNION ALL
  SELECT 'zz9000', 'Driver',     'RTG via Picasso96; needs Kickstart 3.1+ and 68020+', 100 UNION ALL
  SELECT 'zz9000', 'Revisions',  'R-1 to R-4; R-1 and R-2 need the trace-cut fix', 110 UNION ALL
  SELECT 'zz9000', 'Add-on',     'ZZ9000AX audio card, firmware 1.10 or later', 120 UNION ALL
  SELECT 'zz9000', 'Reference',   'https://mntre.com/media/ZZ9000_info_md/2019-08-09-ZZ9000-resources.html', 130
) f JOIN hardware_models hm ON hm.slug = f.model;

-- The set, which is the whole point of the example.
INSERT IGNORE INTO model_fits (model_id, fits_model_id)
SELECT card.id, mach.id
  FROM hardware_models card
  JOIN hardware_models mach ON mach.slug IN ('amiga-2000', 'amiga-3000', 'amiga-4000')
 WHERE card.slug IN ('bigram-2008', 'zz9000');


-- What the Zorro machines physically have. A card is matched against these, so a
-- machine with no slots declared can hold nothing.
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, s.qty, s.note FROM (
  SELECT 'amiga-2000' AS model, 'z2' AS code, 5 AS qty, 'Zorro II bus' AS note UNION ALL
  SELECT 'amiga-2000', 'cpu',    1, 'CPU slot'                      UNION ALL
  SELECT 'amiga-3000', 'z3', 4, 'Zorro III, backwards compatible with Zorro II' UNION ALL
  SELECT 'amiga-3000', 'z2', 4, 'Zorro II cards work in the same slots'         UNION ALL
  SELECT 'amiga-3000', 'cpu',    1, 'CPU slot'                      UNION ALL
  SELECT 'amiga-4000', 'z3', 4, 'Zorro III, backwards compatible with Zorro II' UNION ALL
  SELECT 'amiga-4000', 'z2', 4, 'Zorro II cards work in the same slots'         UNION ALL
  SELECT 'amiga-4000', 'cpu',    1, 'CPU slot'
) s
  JOIN hardware_models hm ON hm.slug = s.model
  JOIN platforms p        ON p.id = hm.platform_id
  JOIN hardware_vocab hv  ON hv.platform_id = p.id AND hv.code = s.code;

-- ---------------------------------------------------------------------------
-- More Commodore, because it is what most of these shelves actually hold
--
-- The same rows as starter-data/hardware_machines.json. Two files describe the
-- starter set - this one for a fresh install, the JSON for a synchronise - and
-- tests/templates.php asserts they agree by syncing over a seeded database and
-- requiring that nothing is added. Adding machines to one and not the other is
-- exactly what that assertion is for, and it caught this.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_models (vendor_id, platform_id, category_id, name, slug, year_from, notes, sort_order)
SELECT v.id, p.id, c.id, x.name, x.slug, x.yr, x.notes, x.so
  FROM (
  SELECT 'PET 2001' AS name, 'pet-2001' AS slug, 1977 AS yr, 'The first one. Calculator keyboard and a built-in cassette deck.' AS notes,
         'commodore' AS ven, 'pet' AS plat, 'computers' AS cat, 300 AS so UNION ALL
  SELECT 'CBM 4032', 'pet-4032', 1980,
         '40-column PET with the full keyboard and BASIC 4.0.',
         'commodore', 'pet', 'computers', 310 UNION ALL
  SELECT 'CBM 8032', 'cbm-8032', 1980,
         'The 80-column business machine. What most European offices meant by a PET.',
         'commodore', 'pet', 'computers', 320 UNION ALL
  SELECT 'VIC-20', 'vic-20', 1980,
         'The first computer of any kind to sell a million. 5 KB, and most of it spoken for.',
         'commodore', 'vic-20', 'computers', 330 UNION ALL
  SELECT 'Commodore 64', 'c64-breadbin', 1982,
         'The breadbin. The best-selling computer model of all time, and the reason half this catalogue exists.',
         'commodore', 'c64', 'computers', 340 UNION ALL
  SELECT 'Commodore 64C', 'c64c', 1986,
         'The restyled C64 in the flatter case, usually with the 8580 SID - which is why a C64C and a breadbin do not sound quite alike.',
         'commodore', 'c64', 'computers', 350 UNION ALL
  SELECT 'SX-64', 'c64-sx64', 1984,
         'The portable C64, with a 5" colour screen and a 1541 built in. Portable in the sense that it has a handle.',
         'commodore', 'c64', 'computers', 360 UNION ALL
  SELECT 'Commodore 128', 'c128', 1985,
         'Three machines in one case: native 128 mode, a genuine C64 mode, and CP/M on a second processor.',
         'commodore', 'c64', 'computers', 370 UNION ALL
  SELECT 'Commodore 128D', 'c128d', 1986,
         'The 128 in a desktop case with the 1571 built in and a detachable keyboard.',
         'commodore', 'c64', 'computers', 380 UNION ALL
  SELECT 'Commodore 16', 'c16', 1984,
         'The 264 series in a breadbin case. Not C64 compatible, which is most of what anybody remembers about it.',
         'commodore', 'plus4', 'computers', 390 UNION ALL
  SELECT 'Plus/4', 'plus4', 1984,
         '64 KB and four applications in ROM. The productivity machine nobody had asked for.',
         'commodore', 'plus4', 'computers', 400 UNION ALL
  SELECT 'Amiga 1000', 'amiga-1000', 1985,
         'The first one, with Kickstart loaded from floppy at every boot and the developers'' signatures moulded into the case.',
         'commodore', 'amiga', 'computers', 410 UNION ALL
  SELECT 'Amiga 500+', 'amiga-500-plus', 1991,
         'An A500 with ECS, Kickstart 2.04 and a battery on the board - which is worth checking before you plug one in.',
         'commodore', 'amiga', 'computers', 420 UNION ALL
  SELECT 'Amiga 600', 'amiga-600', 1992,
         'The small one, with PCMCIA and room for a 2.5" drive, and no numeric keypad.',
         'commodore', 'amiga', 'computers', 430 UNION ALL
  SELECT 'Amiga 1200', 'amiga-1200', 1992,
         'AGA in a wedge. The one most people mean when they say they still have an Amiga.',
         'commodore', 'amiga', 'computers', 440 UNION ALL
  SELECT 'Amiga 3000T', 'amiga-3000t', 1991,
         'The tower 3000, with more Zorro slots than anybody filled.',
         'commodore', 'amiga', 'computers', 450 UNION ALL
  SELECT 'Amiga 4000T', 'amiga-4000t', 1994,
         'The tower 4000. The last Amiga Commodore shipped before it stopped shipping anything.',
         'commodore', 'amiga', 'computers', 460 UNION ALL
  SELECT 'CDTV', 'cdtv', 1991,
         'An A500 in a black hi-fi case with a CD drive, sold to people who did not want a computer. They did not want this either.',
         'commodore', 'cdtv', 'console', 470 UNION ALL
  SELECT 'Amiga CD32', 'cd32', 1993,
         'An A1200 without the keyboard, and the first 32-bit CD console anywhere. Commodore went under four months later.',
         'commodore', 'cd32', 'console', 480
) x
  JOIN platforms  p ON p.slug = x.plat AND p.library_id IS NULL
  JOIN categories c ON c.slug = x.cat
  LEFT JOIN companies v ON v.slug = x.ven AND v.library_id IS NULL;

-- What each of them describes about itself.
INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT hm.id, f.label, f.val, f.so FROM (
  SELECT 'pet-2001' AS model, 'Processor' AS label, 'MOS 6502 @ 1 MHz' AS val, 10 AS so UNION ALL
  SELECT 'pet-2001', 'Memory', '4 or 8 KB', 20 UNION ALL
  SELECT 'pet-2001', 'Video', '40x25 monochrome, built-in 9" display', 30 UNION ALL
  SELECT 'pet-2001', 'Storage', 'built-in cassette', 40 UNION ALL
  SELECT 'pet-4032', 'Processor', 'MOS 6502 @ 1 MHz', 10 UNION ALL
  SELECT 'pet-4032', 'Memory', '32 KB', 20 UNION ALL
  SELECT 'pet-4032', 'Video', '40x25 monochrome', 30 UNION ALL
  SELECT 'pet-4032', 'Storage', 'external, over IEEE-488', 40 UNION ALL
  SELECT 'cbm-8032', 'Processor', 'MOS 6502 @ 1 MHz', 10 UNION ALL
  SELECT 'cbm-8032', 'Memory', '32 KB', 20 UNION ALL
  SELECT 'cbm-8032', 'Video', '80x25 monochrome', 30 UNION ALL
  SELECT 'cbm-8032', 'Storage', 'external, over IEEE-488', 40 UNION ALL
  SELECT 'vic-20', 'Processor', 'MOS 6502 @ 1.02 MHz PAL', 10 UNION ALL
  SELECT 'vic-20', 'Memory', '5 KB, 3.5 KB free to BASIC', 20 UNION ALL
  SELECT 'vic-20', 'Video', 'VIC, 22x23 text', 30 UNION ALL
  SELECT 'vic-20', 'Sound', 'VIC, three tones and noise', 40 UNION ALL
  SELECT 'vic-20', 'Storage', 'cassette or 1540 floppy', 50 UNION ALL
  SELECT 'c64-breadbin', 'Processor', 'MOS 6510 @ 0.985 MHz PAL', 10 UNION ALL
  SELECT 'c64-breadbin', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'c64-breadbin', 'Video', 'VIC-II 6569 PAL', 30 UNION ALL
  SELECT 'c64-breadbin', 'Sound', 'SID 6581', 40 UNION ALL
  SELECT 'c64-breadbin', 'Kernal', '901227-03', 50 UNION ALL
  SELECT 'c64-breadbin', 'Storage', 'cassette or 1541 floppy', 60 UNION ALL
  SELECT 'c64c', 'Processor', 'MOS 8500 @ 0.985 MHz PAL', 10 UNION ALL
  SELECT 'c64c', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'c64c', 'Video', 'VIC-II 8565 PAL', 30 UNION ALL
  SELECT 'c64c', 'Sound', 'SID 8580', 40 UNION ALL
  SELECT 'c64c', 'Storage', 'cassette or 1541-II floppy', 50 UNION ALL
  SELECT 'c64-sx64', 'Processor', 'MOS 6510 @ 0.985 MHz PAL', 10 UNION ALL
  SELECT 'c64-sx64', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'c64-sx64', 'Video', 'VIC-II, built-in 5" colour CRT', 30 UNION ALL
  SELECT 'c64-sx64', 'Sound', 'SID 6581', 40 UNION ALL
  SELECT 'c64-sx64', 'Storage', 'built-in 1541 drive, no cassette port', 50 UNION ALL
  SELECT 'c128', 'Processor', 'MOS 8502 @ 2 MHz, plus Z80', 10 UNION ALL
  SELECT 'c128', 'Memory', '128 KB', 20 UNION ALL
  SELECT 'c128', 'Video', 'VIC-II and VDC 8563 for 80 columns', 30 UNION ALL
  SELECT 'c128', 'Sound', 'SID 8580', 40 UNION ALL
  SELECT 'c128', 'Storage', 'cassette or 1571 floppy', 50 UNION ALL
  SELECT 'c128d', 'Processor', 'MOS 8502 @ 2 MHz, plus Z80', 10 UNION ALL
  SELECT 'c128d', 'Memory', '128 KB', 20 UNION ALL
  SELECT 'c128d', 'Video', 'VIC-II and VDC 8563 for 80 columns', 30 UNION ALL
  SELECT 'c128d', 'Sound', 'SID 8580', 40 UNION ALL
  SELECT 'c128d', 'Storage', 'built-in 1571 drive', 50 UNION ALL
  SELECT 'c16', 'Processor', 'MOS 7501 @ 0.886 MHz PAL', 10 UNION ALL
  SELECT 'c16', 'Memory', '16 KB', 20 UNION ALL
  SELECT 'c16', 'Video', 'TED, 121 colours', 30 UNION ALL
  SELECT 'c16', 'Sound', 'TED, two tones', 40 UNION ALL
  SELECT 'c16', 'Storage', 'cassette or 1551 floppy', 50 UNION ALL
  SELECT 'plus4', 'Processor', 'MOS 7501 @ 0.886 MHz PAL', 10 UNION ALL
  SELECT 'plus4', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'plus4', 'Video', 'TED, 121 colours', 30 UNION ALL
  SELECT 'plus4', 'Sound', 'TED, two tones', 40 UNION ALL
  SELECT 'plus4', 'Storage', 'cassette or 1551 floppy', 50 UNION ALL
  SELECT 'amiga-1000', 'Processor', '68000 @ 7.16 MHz', 10 UNION ALL
  SELECT 'amiga-1000', 'Memory', '256 KB, 512 KB with the front expansion', 20 UNION ALL
  SELECT 'amiga-1000', 'Video', 'OCS', 30 UNION ALL
  SELECT 'amiga-1000', 'Kickstart', 'loaded from disk', 40 UNION ALL
  SELECT 'amiga-1000', 'Storage', 'floppy', 50 UNION ALL
  SELECT 'amiga-500-plus', 'Processor', '68000 @ 7.16 MHz', 10 UNION ALL
  SELECT 'amiga-500-plus', 'Memory', '1 MB chip', 20 UNION ALL
  SELECT 'amiga-500-plus', 'Video', 'ECS', 30 UNION ALL
  SELECT 'amiga-500-plus', 'Kickstart', '2.04', 40 UNION ALL
  SELECT 'amiga-500-plus', 'Storage', 'floppy', 50 UNION ALL
  SELECT 'amiga-600', 'Processor', '68000 @ 7.16 MHz', 10 UNION ALL
  SELECT 'amiga-600', 'Memory', '1 MB chip', 20 UNION ALL
  SELECT 'amiga-600', 'Video', 'ECS', 30 UNION ALL
  SELECT 'amiga-600', 'Kickstart', '2.05', 40 UNION ALL
  SELECT 'amiga-600', 'Storage', 'floppy, IDE 2.5"', 50 UNION ALL
  SELECT 'amiga-1200', 'Processor', '68EC020 @ 14.19 MHz', 10 UNION ALL
  SELECT 'amiga-1200', 'Memory', '2 MB chip', 20 UNION ALL
  SELECT 'amiga-1200', 'Video', 'AGA', 30 UNION ALL
  SELECT 'amiga-1200', 'Kickstart', '3.0', 40 UNION ALL
  SELECT 'amiga-1200', 'Storage', 'floppy, IDE 2.5"', 50 UNION ALL
  SELECT 'amiga-3000t', 'Processor', '68030 @ 25 MHz', 10 UNION ALL
  SELECT 'amiga-3000t', 'Memory', '2 MB chip, 16 MB fast', 20 UNION ALL
  SELECT 'amiga-3000t', 'Video', 'ECS', 30 UNION ALL
  SELECT 'amiga-3000t', 'Kickstart', '2.04', 40 UNION ALL
  SELECT 'amiga-3000t', 'Storage', 'floppy, SCSI', 50 UNION ALL
  SELECT 'amiga-4000t', 'Processor', '68040 @ 25 MHz', 10 UNION ALL
  SELECT 'amiga-4000t', 'Memory', '2 MB chip, 16 MB fast', 20 UNION ALL
  SELECT 'amiga-4000t', 'Video', 'AGA', 30 UNION ALL
  SELECT 'amiga-4000t', 'Kickstart', '3.1', 40 UNION ALL
  SELECT 'amiga-4000t', 'Storage', 'floppy, SCSI and IDE', 50 UNION ALL
  SELECT 'cdtv', 'Processor', '68000 @ 7.16 MHz', 10 UNION ALL
  SELECT 'cdtv', 'Memory', '1 MB chip', 20 UNION ALL
  SELECT 'cdtv', 'Video', 'ECS', 30 UNION ALL
  SELECT 'cdtv', 'Kickstart', '1.3 with CDTV extensions', 40 UNION ALL
  SELECT 'cdtv', 'Storage', 'CD-ROM, single speed', 50 UNION ALL
  SELECT 'cd32', 'Processor', '68EC020 @ 14.19 MHz', 10 UNION ALL
  SELECT 'cd32', 'Memory', '2 MB chip', 20 UNION ALL
  SELECT 'cd32', 'Video', 'AGA', 30 UNION ALL
  SELECT 'cd32', 'Kickstart', '3.1', 40 UNION ALL
  SELECT 'cd32', 'Storage', 'CD-ROM, double speed', 50
) f JOIN hardware_models hm ON hm.slug = f.model;

-- And what each of them physically has. Matched to this platform's own
-- vocabulary, so 'cart' on a PET is the PET's connector and not the C64's.
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, s.qty, s.note FROM (
  SELECT 'pet-2001' AS model, 'cart' AS code, 1 AS qty, 'memory expansion connector' AS note UNION ALL
  SELECT 'pet-2001', 'joy', 1, 'user port games adapter' UNION ALL
  SELECT 'pet-2001', 'serial', 1, 'IEEE-488 bus' UNION ALL
  SELECT 'pet-2001', 'tape', 1, 'second cassette port' UNION ALL
  SELECT 'pet-2001', 'user', 1, 'user port' UNION ALL
  SELECT 'pet-4032', 'serial', 1, 'IEEE-488 bus' UNION ALL
  SELECT 'pet-4032', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'pet-4032', 'user', 1, 'user port' UNION ALL
  SELECT 'cbm-8032', 'serial', 1, 'IEEE-488 bus' UNION ALL
  SELECT 'cbm-8032', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'cbm-8032', 'user', 1, 'user port' UNION ALL
  SELECT 'vic-20', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'vic-20', 'joy', 1, 'control port' UNION ALL
  SELECT 'vic-20', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'vic-20', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'vic-20', 'user', 1, 'user port' UNION ALL
  SELECT 'c64-breadbin', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c64-breadbin', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c64-breadbin', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c64-breadbin', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'c64-breadbin', 'user', 1, 'user port' UNION ALL
  SELECT 'c64c', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c64c', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c64c', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c64c', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'c64c', 'user', 1, 'user port' UNION ALL
  SELECT 'c64-sx64', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c64-sx64', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c64-sx64', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c64-sx64', 'user', 1, 'user port' UNION ALL
  SELECT 'c128', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c128', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c128', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c128', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'c128', 'user', 1, 'user port' UNION ALL
  SELECT 'c128d', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c128d', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c128d', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c128d', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'c128d', 'user', 1, 'user port' UNION ALL
  SELECT 'c16', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'c16', 'joy', 2, 'control ports' UNION ALL
  SELECT 'c16', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'c16', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'c16', 'user', 1, 'user port' UNION ALL
  SELECT 'plus4', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'plus4', 'joy', 2, 'control ports' UNION ALL
  SELECT 'plus4', 'serial', 1, 'serial (IEC) bus' UNION ALL
  SELECT 'plus4', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'plus4', 'user', 1, 'user port' UNION ALL
  SELECT 'amiga-1000', 'side', 1, '86-pin expansion bus' UNION ALL
  SELECT 'amiga-1000', 'cpu', 1, 'CPU socket' UNION ALL
  SELECT 'amiga-1000', 'ser', 1, 'serial port' UNION ALL
  SELECT 'amiga-1000', 'par', 1, 'parallel port' UNION ALL
  SELECT 'amiga-500-plus', 'trap', 1, 'trapdoor, under the machine' UNION ALL
  SELECT 'amiga-500-plus', 'side', 1, 'left side expansion bus' UNION ALL
  SELECT 'amiga-500-plus', 'cpu', 1, 'CPU socket' UNION ALL
  SELECT 'amiga-500-plus', 'clk', 1, 'clock port' UNION ALL
  SELECT 'amiga-600', 'trap', 1, 'trapdoor, under the machine' UNION ALL
  SELECT 'amiga-600', 'pcm', 1, 'PCMCIA type II' UNION ALL
  SELECT 'amiga-600', 'clk', 1, 'clock port' UNION ALL
  SELECT 'amiga-1200', 'trap', 1, 'trapdoor accelerator slot' UNION ALL
  SELECT 'amiga-1200', 'pcm', 1, 'PCMCIA type II' UNION ALL
  SELECT 'amiga-1200', 'clk', 1, 'clock port' UNION ALL
  SELECT 'amiga-3000t', 'z3', 5, 'Zorro III' UNION ALL
  SELECT 'amiga-3000t', 'z2', 5, 'Zorro II cards work in the same slots' UNION ALL
  SELECT 'amiga-3000t', 'isa', 4, 'ISA, bridgeboard only' UNION ALL
  SELECT 'amiga-3000t', 'cpu', 1, 'CPU slot' UNION ALL
  SELECT 'amiga-3000t', 'vid', 1, 'video slot' UNION ALL
  SELECT 'amiga-4000t', 'z3', 5, 'Zorro III' UNION ALL
  SELECT 'amiga-4000t', 'z2', 5, 'Zorro II cards work in the same slots' UNION ALL
  SELECT 'amiga-4000t', 'isa', 4, 'ISA, bridgeboard only' UNION ALL
  SELECT 'amiga-4000t', 'cpu', 1, 'CPU slot' UNION ALL
  SELECT 'amiga-4000t', 'vid', 1, 'video slot' UNION ALL
  SELECT 'cdtv', 'misc', 1, 'front expansion bay' UNION ALL
  SELECT 'cdtv', 'ser', 1, 'serial port' UNION ALL
  SELECT 'cdtv', 'par', 1, 'parallel port' UNION ALL
  SELECT 'cd32', 'misc', 1, 'rear expansion connector, for the MPEG and SX-1 modules' UNION ALL
  SELECT 'cd32', 'ser', 1, 'AUX serial port'
) s
  JOIN hardware_models hm ON hm.slug = s.model
  JOIN platforms p        ON p.id = hm.platform_id
  JOIN hardware_vocab hv  ON hv.platform_id = p.id AND hv.code = s.code;

-- ---------------------------------------------------------------------------
-- Who makes what
--
-- `vendors` and `companies` were one table's worth of facts kept in two, so Nintendo
-- and Commodore existed twice with the same country and founding year and no way to
-- keep them agreeing. They are one table now; `makes` is what tells a manufacturer
-- picker from a publisher picker.
--
-- Set here rather than per row, so the tag follows the manufacturer list rather than
-- being retyped beside it.
-- ---------------------------------------------------------------------------
UPDATE companies SET makes = 'hardware'
 WHERE library_id IS NULL AND slug IN ('acorn', 'amstrad', 'apple', 'atari', 'bandai', 'commodore', 'creative', 'csg', 'fujitsu', 'gvp', 'ibm', 'luxor', 'mattel', 'mnt-research', 'nec', 'nintendo', 'phase-5', 'philips', 'sega', 'sharp', 'sinclair', 'snk', 'sony', 'tandy', 'various-vendor', 'waw-elektronik');

-- And the firms that did both. The inserts above take whichever list reached them
-- first; this widens the tag rather than leaving the loser of an INSERT IGNORE with
-- half its truth.
UPDATE companies SET makes = 'hardware,software'
 WHERE library_id IS NULL
   AND slug IN ('nintendo','sega','atari','commodore','sony','microsoft','apple','philips');

-- ---------------------------------------------------------------------------
-- Software models
--
-- The counterpart to the machine and peripheral models above: what a boxed release
-- generally is, so recording one does not mean typing "disks, manual, registration
-- card" again every time. A title made from one starts with its fields and its box
-- contents already filled in.
--
-- Generated from starter-data/software_models.json, which is what template_sync()
-- applies to an existing install. A model in one and not the other is a model that
-- appears or disappears depending on how the instance was set up.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'amiga'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Amiga boxed game, 3.5-inch', 'amiga-boxed-game-disk', '3.5-inch disk',
       1985, 'The common shape of a boxed Amiga game: a card box, disks in a sleeve, a manual, and often a registration card nobody ever posted.', 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Disks', '1 x 3.5-inch', 'How many, and what size', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Copy protection', 'manual lookup', 'Manual lookup, code wheel, dongle, none', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Language', 'English', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Hard drive installable', 'no', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Minimum memory', '512 KB', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card, usually', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disks', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Poster or map', 'Bigger releases only', 50
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-game-disk';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'amiga'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'applications'),
       'Amiga boxed application', 'amiga-boxed-application', '3.5-inch disk',
       1985, 'Productivity and creative software. Thicker manuals than games, a licence, and often a keyfile or dongle.', 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Disks', '2 x 3.5-inch', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Version', NULL, 'The release on the disk, where it has one', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Licence', 'single user', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Minimum memory', '1 MB', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Workbench', '2.0 or later', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disks', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Reference card', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Licence or registration', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Dongle', 'Some professional titles only', 60
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-boxed-application';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'pc'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'PC big box game, CD-ROM', 'pc-cdrom-game-bigbox', 'CD-ROM',
       1993, 'The big cardboard box of the CD era, before jewel cases and then DVD cases took over.', 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Discs', '1 x CD-ROM', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Operating system', 'MS-DOS', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Minimum processor', '386', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Minimum memory', '4 MB', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Sound support', 'Sound Blaster', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Serial or key', NULL, 'Where the box carries one', 60
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Jewel case', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disc', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Quick reference card', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 60
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-game-bigbox';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'pc'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'applications'),
       'PC application, CD-ROM', 'pc-cdrom-application', 'CD-ROM',
       1993, NULL, 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Discs', '1 x CD-ROM', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Version', NULL, NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Operating system', 'Windows 95', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Licence', 'single user', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Serial or key', NULL, NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disc', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Licence or certificate of authenticity', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-cdrom-application';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'mega-drive'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Mega Drive boxed cartridge', 'mega-drive-cart-game', 'cartridge',
       1988, 'A console release: plastic clamshell, cartridge, manual. No install, no disks, no memory requirement.', 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', 'PAL, NTSC-U/C or NTSC-J', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridge size', NULL, 'Megabits, where it is worth knowing', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Save', 'password', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Players', '1-2', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Case', 'Clamshell, usually', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Inlay or slipcover', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'mega-drive-cart-game';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'game-boy'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Game Boy boxed cartridge', 'game-boy-cart-game', 'cartridge',
       1989, NULL, 0;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Save', 'battery', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Players', '1', 'Link cable titles say 2', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Inner tray or insert', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'game-boy-cart-game';

-- ---------------------------------------------------------------------------
-- The rest of the machines: consoles, handhelds and the other computers
--
-- Generated from starter-data/hardware_machines.json. Two files describe the
-- starter set and tests/templates.php asserts they agree by synchronising over a
-- seeded database and requiring that nothing is added.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_models (vendor_id, platform_id, category_id, name, slug, year_from, notes, sort_order)
SELECT v.id, p.id, c.id, x.name, x.slug, x.yr, x.notes, x.so
  FROM (
  SELECT 'NES (front loader)' AS name, 'nes-toaster' AS slug, 1985 AS yr, 'The front-loading NES. The loading mechanism is the thing that fails, and the reason so many need the pins reseating.' AS notes,
         'nintendo' AS ven, 'nes' AS plat, 'console' AS cat, 490 AS so UNION ALL
  SELECT 'NES (top loader)', 'nes-top-loader', 1993,
         'The later top loader. No lockout chip and no rotting pin connector, but composite out was dropped for RF.',
         'nintendo', 'nes', 'console', 500 UNION ALL
  SELECT 'Super Nintendo', 'snes-console', 1990,
         'Mode 7 and the S-SMP sound chip. The PAL machine runs at 50 Hz and it shows.',
         'nintendo', 'snes', 'console', 510 UNION ALL
  SELECT 'Nintendo 64', 'n64-console', 1996,
         'Four controller ports as standard, which is most of what people remember about it.',
         'nintendo', 'n64', 'console', 520 UNION ALL
  SELECT 'Mega Drive (model 1)', 'mega-drive-1', 1988,
         'The one with the headphone socket and the better sound. Genesis in North America.',
         'sega', 'mega-drive', 'console', 530 UNION ALL
  SELECT 'Mega Drive (model 2)', 'mega-drive-2', 1993,
         'Smaller, cheaper, no headphone socket, and mono unless you take stereo from the AV port.',
         'sega', 'mega-drive', 'console', 540 UNION ALL
  SELECT 'Mega-CD (model 2)', 'mega-cd-2', 1993,
         'A CD drive, a second 68000 and a scaling chip, sat under a Mega Drive.',
         'sega', 'mega-cd', 'console', 550 UNION ALL
  SELECT 'Sega Saturn', 'saturn-console', 1994,
         'Two SH-2s and a reputation for being hard to write for. The PAL machine came late and thin on titles.',
         'sega', 'saturn', 'console', 560 UNION ALL
  SELECT 'Dreamcast', 'dreamcast-console', 1998,
         'GD-ROM, a modem in the box, and the last console Sega made.',
         'sega', 'dreamcast', 'console', 570 UNION ALL
  SELECT 'Master System II', 'master-system-2', 1990,
         'Cheaper, smaller, no card slot and no reset button. Alex Kidd is built in.',
         'sega', 'master-system', 'console', 580 UNION ALL
  SELECT 'PlayStation (SCPH-1002)', 'playstation-scph1002', 1995,
         'The early PAL machine, with the parallel port on the back that later revisions dropped.',
         'sony', 'playstation', 'console', 590 UNION ALL
  SELECT 'Atari 2600 VCS', 'atari-2600-vcs', 1977,
         'Woodgrain and six switches. The machine that made a cartridge a thing you bought.',
         'atari', 'atari-2600', 'console', 600 UNION ALL
  SELECT 'Neo Geo AES', 'neo-geo-aes', 1990,
         'The arcade board in a home case, and cartridges that cost as much as a console.',
         'snk', 'neo-geo', 'console', 620 UNION ALL
  SELECT 'PC Engine (white)', 'pc-engine-core', 1987,
         'HuCards the size of a credit card, and the smallest console anybody had made.',
         'nec', 'pc-engine', 'console', 630 UNION ALL
  SELECT 'Intellivision', 'intellivision-master', 1979,
         'Disc controllers with a keypad, and overlays that slid in over them.',
         'mattel', 'intellivision', 'console', 640 UNION ALL
  SELECT 'ColecoVision', 'colecovision-console', 1982,
         'The expansion module let it play 2600 cartridges, which Atari went to court about.',
         'various-vendor', 'colecovision', 'console', 650 UNION ALL
  SELECT 'Vectrex', 'vectrex-console', 1982,
         'Its own vector monitor built in, so it never needed a television and never looked like anything else.',
         'various-vendor', 'vectrex', 'console', 660 UNION ALL
  SELECT '3DO FZ-1', '3do-fz1', 1993,
         'Panasonic''s build of a standard other people were meant to licence. Almost nobody did.',
         'various-vendor', '3do', 'console', 670 UNION ALL
  SELECT 'Atari Jaguar', 'jaguar-console', 1993,
         'Sold as 64-bit, which was true of two of the chips and an argument about the rest.',
         'atari', 'jaguar', 'console', 680 UNION ALL
  SELECT 'Philips CD-i 910', 'cdi-910', 1991,
         'Sold as an interactive appliance rather than a console, which is why it is shaped like a video recorder.',
         'philips', 'cd-i', 'console', 690 UNION ALL
  SELECT 'Game Boy Pocket', 'game-boy-pocket', 1996,
         'Smaller, two AAAs instead of four AAs, and a screen you can actually read.',
         'nintendo', 'game-boy', 'handheld', 700 UNION ALL
  SELECT 'Game Boy Color', 'game-boy-color', 1998,
         'Backwards compatible, and the colour palette it applies to old cartridges is chosen by a key combination at boot.',
         'nintendo', 'game-boy', 'handheld', 710 UNION ALL
  SELECT 'Game Boy Advance', 'gba-original', 2001,
         'No backlight, which is the entire reason the SP exists.',
         'nintendo', 'gba', 'handheld', 720 UNION ALL
  SELECT 'Game Gear', 'game-gear-handheld', 1990,
         'A backlit Master System that ate six AA batteries in four hours. The capacitors have all failed by now.',
         'sega', 'game-gear', 'handheld', 730 UNION ALL
  SELECT 'Atari Lynx II', 'lynx-ii', 1991,
         'Colour, backlit and left-handed if you wanted, three years before anybody else managed the first two.',
         'atari', 'lynx', 'handheld', 740 UNION ALL
  SELECT 'WonderSwan Color', 'wonderswan-color', 2000,
         'Held either way up, and it ran for thirty hours on one AA. Japan only.',
         'bandai', 'wonderswan', 'handheld', 750 UNION ALL
  SELECT 'ZX Spectrum 48K', 'zx-spectrum-48k', 1982,
         'Rubber keys and colour clash. The machine most British bedrooms learned to program on.',
         'sinclair', 'zx-spectrum', 'computers', 760 UNION ALL
  SELECT 'ZX Spectrum +2', 'zx-spectrum-128-plus2', 1986,
         'Amstrad''s Spectrum, with the tape deck built in and an AY chip that made the music worth listening to.',
         'sinclair', 'zx-spectrum', 'computers', 770 UNION ALL
  SELECT 'Atari 520ST', 'atari-520st', 1985,
         'MIDI in and out as standard, which is why so many studios still have one.',
         'atari', 'atari-st', 'computers', 780 UNION ALL
  SELECT 'Atari 1040STF', 'atari-1040stf', 1986,
         'A megabyte and the floppy drive inside the case. The one most people had.',
         'atari', 'atari-st', 'computers', 790 UNION ALL
  SELECT 'Atari Mega ST', 'atari-mega-st', 1987,
         'Detached keyboard, a blitter and an internal bus, sold at people who did work on it.',
         'atari', 'atari-st', 'computers', 800 UNION ALL
  SELECT 'Amstrad CPC 464', 'amstrad-cpc-464', 1984,
         'Sold with its own monitor, which powered the machine — so a dead monitor is a dead computer.',
         'amstrad', 'amstrad-cpc', 'computers', 810 UNION ALL
  SELECT 'Amstrad CPC 6128', 'amstrad-cpc-6128', 1985,
         '128 KB and a 3-inch disk drive, in the format only Amstrad ever really used.',
         'amstrad', 'amstrad-cpc', 'computers', 820 UNION ALL
  SELECT 'MSX2', 'msx2-machine', 1985,
         'A standard rather than a machine, so a Sony and a Philips run the same cartridges.',
         'various-vendor', 'msx', 'computers', 830 UNION ALL
  SELECT 'Apple IIe', 'apple-iie', 1983,
         'Seven expansion slots and a machine that stayed on sale for eleven years.',
         'apple', 'apple-ii', 'computers', 840 UNION ALL
  SELECT 'BBC Micro Model B', 'bbc-micro-b', 1981,
         'The school computer, with more ports on the back than anything else of its size.',
         'acorn', 'bbc-micro', 'computers', 850 UNION ALL
  SELECT 'Acorn Electron', 'acorn-electron-machine', 1983,
         'The cut-down BBC. One chip did most of it, and it was slower for the same reason it was cheaper.',
         'acorn', 'acorn-electron', 'computers', 860 UNION ALL
  SELECT 'Acorn A3000', 'archimedes-a3000', 1989,
         'ARM in a home computer, six years before anybody was putting it in a telephone.',
         'acorn', 'archimedes', 'computers', 870 UNION ALL
  SELECT 'Atari 800XL', 'atari-800xl', 1983,
         'ANTIC and GTIA doing display lists, years before anyone called it a graphics chip.',
         'atari', 'atari-8bit', 'computers', 880 UNION ALL
  SELECT 'Atari 130XE', 'atari-130xe', 1985,
         '128 KB, bank switched, in the flatter case that matched the ST.',
         'atari', 'atari-8bit', 'computers', 890 UNION ALL
  SELECT 'Macintosh Plus', 'mac-plus', 1986,
         'SCSI and a megabyte, and the first Mac you could sensibly expand.',
         'apple', 'mac-68k', 'computers', 900 UNION ALL
  SELECT 'Sharp X68000 EXPERT', 'x68000-expert', 1987,
         'An arcade board Sharp sold as a home computer, in a case shaped like two towers.',
         'sharp', 'x68000', 'computers', 910 UNION ALL
  SELECT 'NEC PC-9801VX', 'pc-9801-vx', 1986,
         'The Japanese office standard for a decade, and nothing like a PC inside.',
         'nec', 'pc-9801', 'computers', 920 UNION ALL
  SELECT 'TRS-80 Model I', 'trs-80-model-1', 1977,
         'Sold in a high street chain, which is most of why it sold at all.',
         'tandy', 'trs-80', 'computers', 930 UNION ALL
  SELECT 'Dragon 32', 'dragon-32-machine', 1982,
         'Built in Wales, near enough a CoCo, and incompatible with everything British around it.',
         'various-vendor', 'dragon-32', 'computers', 940 UNION ALL
  SELECT 'Oric Atmos', 'oric-atmos', 1984,
         'The Oric-1 with a keyboard you could type on, which was the complaint it was built to answer.',
         'various-vendor', 'oric', 'computers', 950 UNION ALL
  SELECT 'SAM Coupé', 'sam-coupe-machine', 1989,
         'A Spectrum successor that arrived after everyone had bought an Amiga.',
         'various-vendor', 'sam-coupe', 'computers', 960 UNION ALL
  SELECT 'Sinclair QL', 'sinclair-ql-machine', 1984,
         'Microdrives, a 68008, and a launch so early the first machines shipped with a ROM hanging out of the back.',
         'sinclair', 'sinclair-ql', 'computers', 970 UNION ALL
  SELECT 'ZX81', 'zx81-machine', 1981,
         'One kilobyte, a membrane keyboard, and a RAM pack that fell off if you breathed on it.',
         'sinclair', 'zx81', 'computers', 980 UNION ALL
  SELECT 'Luxor ABC 80', 'abc-80-machine', 1978,
         'The Swedish school computer, on an ABC bus and speaking BASIC in Swedish error messages.',
         'luxor', 'abc-80', 'computers', 990
) x
  JOIN platforms  p ON p.slug = x.plat AND p.library_id IS NULL
  JOIN categories c ON c.slug = x.cat
  LEFT JOIN companies v ON v.slug = x.ven AND v.library_id IS NULL;

INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT hm.id, f.label, f.val, f.so FROM (
  SELECT 'nes-toaster' AS model, 'Processor' AS label, 'Ricoh 2A03 @ 1.79 MHz' AS val, 10 AS so UNION ALL
  SELECT 'nes-toaster', 'Memory', '2 KB work, 2 KB video', 20 UNION ALL
  SELECT 'nes-toaster', 'Video', 'PPU, 256x240', 30 UNION ALL
  SELECT 'nes-toaster', 'Region', 'NTSC or PAL', 40 UNION ALL
  SELECT 'nes-top-loader', 'Processor', 'Ricoh 2A03 @ 1.79 MHz', 10 UNION ALL
  SELECT 'nes-top-loader', 'Memory', '2 KB work, 2 KB video', 20 UNION ALL
  SELECT 'nes-top-loader', 'Video', 'PPU, RF only', 30 UNION ALL
  SELECT 'snes-console', 'Processor', 'Ricoh 5A22 @ 3.58 MHz', 10 UNION ALL
  SELECT 'snes-console', 'Memory', '128 KB work, 64 KB video', 20 UNION ALL
  SELECT 'snes-console', 'Video', 'PPU1/PPU2, 256x224', 30 UNION ALL
  SELECT 'snes-console', 'Sound', 'S-SMP with SPC700', 40 UNION ALL
  SELECT 'n64-console', 'Processor', 'NEC VR4300 @ 93.75 MHz', 10 UNION ALL
  SELECT 'n64-console', 'Memory', '4 MB RDRAM, 8 MB with the Expansion Pak', 20 UNION ALL
  SELECT 'n64-console', 'Video', 'Reality Coprocessor', 30 UNION ALL
  SELECT 'n64-console', 'Storage', 'cartridge', 40 UNION ALL
  SELECT 'mega-drive-1', 'Processor', '68000 @ 7.6 MHz, plus Z80', 10 UNION ALL
  SELECT 'mega-drive-1', 'Memory', '64 KB work, 64 KB video', 20 UNION ALL
  SELECT 'mega-drive-1', 'Video', 'VDP, 320x224', 30 UNION ALL
  SELECT 'mega-drive-1', 'Sound', 'YM2612 and SN76489', 40 UNION ALL
  SELECT 'mega-drive-2', 'Processor', '68000 @ 7.6 MHz, plus Z80', 10 UNION ALL
  SELECT 'mega-drive-2', 'Memory', '64 KB work, 64 KB video', 20 UNION ALL
  SELECT 'mega-drive-2', 'Video', 'VDP, 320x224', 30 UNION ALL
  SELECT 'mega-drive-2', 'Sound', 'YM3438 and SN76489', 40 UNION ALL
  SELECT 'mega-cd-2', 'Processor', '68000 @ 12.5 MHz', 10 UNION ALL
  SELECT 'mega-cd-2', 'Memory', '6 MB total across the two machines', 20 UNION ALL
  SELECT 'mega-cd-2', 'Storage', 'CD-ROM, double speed', 30 UNION ALL
  SELECT 'mega-cd-2', 'Backup', 'internal battery RAM', 40 UNION ALL
  SELECT 'saturn-console', 'Processor', 'two Hitachi SH-2 @ 28.6 MHz', 10 UNION ALL
  SELECT 'saturn-console', 'Memory', '2 MB work, 1.5 MB video', 20 UNION ALL
  SELECT 'saturn-console', 'Storage', 'CD-ROM, double speed', 30 UNION ALL
  SELECT 'saturn-console', 'Backup', 'internal battery RAM', 40 UNION ALL
  SELECT 'dreamcast-console', 'Processor', 'Hitachi SH-4 @ 200 MHz', 10 UNION ALL
  SELECT 'dreamcast-console', 'Memory', '16 MB work, 8 MB video', 20 UNION ALL
  SELECT 'dreamcast-console', 'Storage', 'GD-ROM', 30 UNION ALL
  SELECT 'dreamcast-console', 'Network', '56k modem, broadband adapter later', 40 UNION ALL
  SELECT 'master-system-2', 'Processor', 'Z80 @ 3.58 MHz', 10 UNION ALL
  SELECT 'master-system-2', 'Memory', '8 KB work, 16 KB video', 20 UNION ALL
  SELECT 'master-system-2', 'Video', 'VDP, 256x192', 30 UNION ALL
  SELECT 'playstation-scph1002', 'Processor', 'MIPS R3000A @ 33.9 MHz', 10 UNION ALL
  SELECT 'playstation-scph1002', 'Memory', '2 MB work, 1 MB video', 20 UNION ALL
  SELECT 'playstation-scph1002', 'Storage', 'CD-ROM, double speed', 30 UNION ALL
  SELECT 'playstation-scph1002', 'Sound', 'SPU, 24 voices', 40 UNION ALL
  SELECT 'atari-2600-vcs', 'Processor', 'MOS 6507 @ 1.19 MHz', 10 UNION ALL
  SELECT 'atari-2600-vcs', 'Memory', '128 bytes', 20 UNION ALL
  SELECT 'atari-2600-vcs', 'Video', 'TIA, 160x192', 30 UNION ALL
  SELECT 'atari-2600-vcs', 'Sound', 'TIA, two channels', 40 UNION ALL
  SELECT 'neo-geo-aes', 'Processor', '68000 @ 12 MHz, plus Z80', 10 UNION ALL
  SELECT 'neo-geo-aes', 'Memory', '64 KB work, 84 KB video', 20 UNION ALL
  SELECT 'neo-geo-aes', 'Storage', 'cartridge, up to 716 Mbit', 30 UNION ALL
  SELECT 'pc-engine-core', 'Processor', 'Hudson HuC6280 @ 7.16 MHz', 10 UNION ALL
  SELECT 'pc-engine-core', 'Memory', '8 KB work, 64 KB video', 20 UNION ALL
  SELECT 'pc-engine-core', 'Video', 'HuC6270', 30 UNION ALL
  SELECT 'intellivision-master', 'Processor', 'General Instrument CP1610 @ 894 kHz', 10 UNION ALL
  SELECT 'intellivision-master', 'Memory', '1352 bytes', 20 UNION ALL
  SELECT 'intellivision-master', 'Video', 'STIC, 159x96', 30 UNION ALL
  SELECT 'colecovision-console', 'Processor', 'Z80A @ 3.58 MHz', 10 UNION ALL
  SELECT 'colecovision-console', 'Memory', '1 KB work, 16 KB video', 20 UNION ALL
  SELECT 'colecovision-console', 'Video', 'TMS9928A', 30 UNION ALL
  SELECT 'vectrex-console', 'Processor', '68A09 @ 1.5 MHz', 10 UNION ALL
  SELECT 'vectrex-console', 'Memory', '1 KB', 20 UNION ALL
  SELECT 'vectrex-console', 'Video', 'vector CRT, built in, monochrome', 30 UNION ALL
  SELECT 'vectrex-console', 'Sound', 'AY-3-8912', 40 UNION ALL
  SELECT '3do-fz1', 'Processor', 'ARM60 @ 12.5 MHz', 10 UNION ALL
  SELECT '3do-fz1', 'Memory', '2 MB work, 1 MB video', 20 UNION ALL
  SELECT '3do-fz1', 'Storage', 'CD-ROM, double speed', 30 UNION ALL
  SELECT 'jaguar-console', 'Processor', 'Motorola 68000 @ 13.3 MHz with Tom and Jerry', 10 UNION ALL
  SELECT 'jaguar-console', 'Memory', '2 MB', 20 UNION ALL
  SELECT 'jaguar-console', 'Storage', 'cartridge, CD add-on later', 30 UNION ALL
  SELECT 'cdi-910', 'Processor', '68070 @ 15.5 MHz', 10 UNION ALL
  SELECT 'cdi-910', 'Memory', '1 MB', 20 UNION ALL
  SELECT 'cdi-910', 'Storage', 'CD-i disc', 30 UNION ALL
  SELECT 'game-boy-pocket', 'Processor', 'Sharp LR35902 @ 4.19 MHz', 10 UNION ALL
  SELECT 'game-boy-pocket', 'Memory', '8 KB work, 8 KB video', 20 UNION ALL
  SELECT 'game-boy-pocket', 'Video', '160x144 monochrome', 30 UNION ALL
  SELECT 'game-boy-color', 'Processor', 'Sharp LR35902 @ 8.38 MHz', 10 UNION ALL
  SELECT 'game-boy-color', 'Memory', '32 KB work, 16 KB video', 20 UNION ALL
  SELECT 'game-boy-color', 'Video', '160x144, 56 colours on screen', 30 UNION ALL
  SELECT 'gba-original', 'Processor', 'ARM7TDMI @ 16.8 MHz', 10 UNION ALL
  SELECT 'gba-original', 'Memory', '32 KB internal, 256 KB external', 20 UNION ALL
  SELECT 'gba-original', 'Video', '240x160, unlit', 30 UNION ALL
  SELECT 'game-gear-handheld', 'Processor', 'Z80 @ 3.58 MHz', 10 UNION ALL
  SELECT 'game-gear-handheld', 'Memory', '8 KB work, 16 KB video', 20 UNION ALL
  SELECT 'game-gear-handheld', 'Video', '160x144 backlit colour', 30 UNION ALL
  SELECT 'lynx-ii', 'Processor', '65SC02 @ 4 MHz', 10 UNION ALL
  SELECT 'lynx-ii', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'lynx-ii', 'Video', '160x102 backlit colour', 30 UNION ALL
  SELECT 'wonderswan-color', 'Processor', 'NEC V30 MZ @ 3.072 MHz', 10 UNION ALL
  SELECT 'wonderswan-color', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'wonderswan-color', 'Video', '224x144 colour', 30 UNION ALL
  SELECT 'zx-spectrum-48k', 'Processor', 'Z80A @ 3.5 MHz', 10 UNION ALL
  SELECT 'zx-spectrum-48k', 'Memory', '48 KB', 20 UNION ALL
  SELECT 'zx-spectrum-48k', 'Video', '256x192, attribute colour', 30 UNION ALL
  SELECT 'zx-spectrum-48k', 'Sound', 'beeper', 40 UNION ALL
  SELECT 'zx-spectrum-48k', 'Storage', 'cassette', 50 UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'Processor', 'Z80A @ 3.5 MHz', 10 UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'Memory', '128 KB', 20 UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'Video', '256x192, attribute colour', 30 UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'Sound', 'AY-3-8912', 40 UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'Storage', 'built-in cassette', 50 UNION ALL
  SELECT 'atari-520st', 'Processor', '68000 @ 8 MHz', 10 UNION ALL
  SELECT 'atari-520st', 'Memory', '512 KB', 20 UNION ALL
  SELECT 'atari-520st', 'Video', 'ST shifter, 640x400 mono or 320x200 colour', 30 UNION ALL
  SELECT 'atari-520st', 'Sound', 'YM2149', 40 UNION ALL
  SELECT 'atari-520st', 'Storage', 'external floppy', 50 UNION ALL
  SELECT 'atari-1040stf', 'Processor', '68000 @ 8 MHz', 10 UNION ALL
  SELECT 'atari-1040stf', 'Memory', '1 MB', 20 UNION ALL
  SELECT 'atari-1040stf', 'Video', 'ST shifter, 640x400 mono or 320x200 colour', 30 UNION ALL
  SELECT 'atari-1040stf', 'Sound', 'YM2149', 40 UNION ALL
  SELECT 'atari-1040stf', 'Storage', 'internal 3.5-inch floppy', 50 UNION ALL
  SELECT 'atari-mega-st', 'Processor', '68000 @ 8 MHz with blitter', 10 UNION ALL
  SELECT 'atari-mega-st', 'Memory', '2 or 4 MB', 20 UNION ALL
  SELECT 'atari-mega-st', 'Video', 'ST shifter', 30 UNION ALL
  SELECT 'atari-mega-st', 'Storage', 'internal floppy, ACSI hard disk', 40 UNION ALL
  SELECT 'amstrad-cpc-464', 'Processor', 'Z80A @ 4 MHz', 10 UNION ALL
  SELECT 'amstrad-cpc-464', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'amstrad-cpc-464', 'Video', '6845, 160x200 to 640x200', 30 UNION ALL
  SELECT 'amstrad-cpc-464', 'Sound', 'AY-3-8912', 40 UNION ALL
  SELECT 'amstrad-cpc-464', 'Storage', 'built-in cassette', 50 UNION ALL
  SELECT 'amstrad-cpc-6128', 'Processor', 'Z80A @ 4 MHz', 10 UNION ALL
  SELECT 'amstrad-cpc-6128', 'Memory', '128 KB', 20 UNION ALL
  SELECT 'amstrad-cpc-6128', 'Video', '6845', 30 UNION ALL
  SELECT 'amstrad-cpc-6128', 'Sound', 'AY-3-8912', 40 UNION ALL
  SELECT 'amstrad-cpc-6128', 'Storage', 'built-in 3-inch floppy', 50 UNION ALL
  SELECT 'msx2-machine', 'Processor', 'Z80A @ 3.58 MHz', 10 UNION ALL
  SELECT 'msx2-machine', 'Memory', '64 to 128 KB', 20 UNION ALL
  SELECT 'msx2-machine', 'Video', 'V9938, 512x212', 30 UNION ALL
  SELECT 'msx2-machine', 'Sound', 'AY-3-8910', 40 UNION ALL
  SELECT 'msx2-machine', 'Storage', 'cassette or floppy', 50 UNION ALL
  SELECT 'apple-iie', 'Processor', 'MOS 6502 @ 1.02 MHz', 10 UNION ALL
  SELECT 'apple-iie', 'Memory', '64 KB, 128 KB with the auxiliary card', 20 UNION ALL
  SELECT 'apple-iie', 'Video', '280x192 colour, 80 columns with a card', 30 UNION ALL
  SELECT 'apple-iie', 'Storage', 'Disk II', 40 UNION ALL
  SELECT 'bbc-micro-b', 'Processor', 'MOS 6502 @ 2 MHz', 10 UNION ALL
  SELECT 'bbc-micro-b', 'Memory', '32 KB', 20 UNION ALL
  SELECT 'bbc-micro-b', 'Video', '6845, seven modes', 30 UNION ALL
  SELECT 'bbc-micro-b', 'Sound', 'SN76489', 40 UNION ALL
  SELECT 'bbc-micro-b', 'Storage', 'cassette, floppy with a DFS', 50 UNION ALL
  SELECT 'acorn-electron-machine', 'Processor', 'MOS 6502A @ 2 MHz', 10 UNION ALL
  SELECT 'acorn-electron-machine', 'Memory', '32 KB', 20 UNION ALL
  SELECT 'acorn-electron-machine', 'Video', 'ULA, BBC modes', 30 UNION ALL
  SELECT 'acorn-electron-machine', 'Storage', 'cassette', 40 UNION ALL
  SELECT 'archimedes-a3000', 'Processor', 'ARM2 @ 8 MHz', 10 UNION ALL
  SELECT 'archimedes-a3000', 'Memory', '1 MB', 20 UNION ALL
  SELECT 'archimedes-a3000', 'Video', 'VIDC, 640x480', 30 UNION ALL
  SELECT 'archimedes-a3000', 'Storage', 'internal floppy', 40 UNION ALL
  SELECT 'atari-800xl', 'Processor', 'MOS 6502C @ 1.79 MHz', 10 UNION ALL
  SELECT 'atari-800xl', 'Memory', '64 KB', 20 UNION ALL
  SELECT 'atari-800xl', 'Video', 'ANTIC and GTIA', 30 UNION ALL
  SELECT 'atari-800xl', 'Sound', 'POKEY', 40 UNION ALL
  SELECT 'atari-800xl', 'Storage', 'cassette or 1050 floppy', 50 UNION ALL
  SELECT 'atari-130xe', 'Processor', 'MOS 6502C @ 1.79 MHz', 10 UNION ALL
  SELECT 'atari-130xe', 'Memory', '128 KB, bank switched', 20 UNION ALL
  SELECT 'atari-130xe', 'Video', 'ANTIC and GTIA', 30 UNION ALL
  SELECT 'atari-130xe', 'Sound', 'POKEY', 40 UNION ALL
  SELECT 'atari-130xe', 'Storage', 'cassette or 1050 floppy', 50 UNION ALL
  SELECT 'mac-plus', 'Processor', '68000 @ 7.83 MHz', 10 UNION ALL
  SELECT 'mac-plus', 'Memory', '1 MB, to 4 MB', 20 UNION ALL
  SELECT 'mac-plus', 'Video', '512x342 mono, built in', 30 UNION ALL
  SELECT 'mac-plus', 'Storage', '800 KB floppy, SCSI', 40 UNION ALL
  SELECT 'x68000-expert', 'Processor', '68000 @ 10 MHz', 10 UNION ALL
  SELECT 'x68000-expert', 'Memory', '2 MB', 20 UNION ALL
  SELECT 'x68000-expert', 'Video', 'Cynthia and VSOP, 65536 colours', 30 UNION ALL
  SELECT 'x68000-expert', 'Sound', 'YM2151 and ADPCM', 40 UNION ALL
  SELECT 'x68000-expert', 'Storage', 'two 5.25-inch floppies', 50 UNION ALL
  SELECT 'pc-9801-vx', 'Processor', '80286 @ 10 MHz with V30', 10 UNION ALL
  SELECT 'pc-9801-vx', 'Memory', '640 KB', 20 UNION ALL
  SELECT 'pc-9801-vx', 'Video', '640x400, 16 colours', 30 UNION ALL
  SELECT 'pc-9801-vx', 'Storage', 'two 5.25-inch floppies', 40 UNION ALL
  SELECT 'trs-80-model-1', 'Processor', 'Z80 @ 1.77 MHz', 10 UNION ALL
  SELECT 'trs-80-model-1', 'Memory', '4 to 48 KB', 20 UNION ALL
  SELECT 'trs-80-model-1', 'Video', '64x16 characters, mono', 30 UNION ALL
  SELECT 'trs-80-model-1', 'Storage', 'cassette', 40 UNION ALL
  SELECT 'dragon-32-machine', 'Processor', 'Motorola 6809E @ 0.89 MHz', 10 UNION ALL
  SELECT 'dragon-32-machine', 'Memory', '32 KB', 20 UNION ALL
  SELECT 'dragon-32-machine', 'Video', '6847', 30 UNION ALL
  SELECT 'dragon-32-machine', 'Storage', 'cassette', 40 UNION ALL
  SELECT 'oric-atmos', 'Processor', 'MOS 6502A @ 1 MHz', 10 UNION ALL
  SELECT 'oric-atmos', 'Memory', '48 KB', 20 UNION ALL
  SELECT 'oric-atmos', 'Video', '240x200', 30 UNION ALL
  SELECT 'oric-atmos', 'Sound', 'AY-3-8912', 40 UNION ALL
  SELECT 'oric-atmos', 'Storage', 'cassette', 50 UNION ALL
  SELECT 'sam-coupe-machine', 'Processor', 'Z80B @ 6 MHz', 10 UNION ALL
  SELECT 'sam-coupe-machine', 'Memory', '256 or 512 KB', 20 UNION ALL
  SELECT 'sam-coupe-machine', 'Video', '256x192 to 512x192', 30 UNION ALL
  SELECT 'sam-coupe-machine', 'Sound', 'Philips SAA1099', 40 UNION ALL
  SELECT 'sam-coupe-machine', 'Storage', 'cassette, optional floppy', 50 UNION ALL
  SELECT 'sinclair-ql-machine', 'Processor', '68008 @ 7.5 MHz', 10 UNION ALL
  SELECT 'sinclair-ql-machine', 'Memory', '128 KB', 20 UNION ALL
  SELECT 'sinclair-ql-machine', 'Video', '512x256', 30 UNION ALL
  SELECT 'sinclair-ql-machine', 'Storage', 'two Microdrives', 40 UNION ALL
  SELECT 'zx81-machine', 'Processor', 'Z80A @ 3.25 MHz', 10 UNION ALL
  SELECT 'zx81-machine', 'Memory', '1 KB, 16 KB with the RAM pack', 20 UNION ALL
  SELECT 'zx81-machine', 'Video', '64x44 blocks, mono', 30 UNION ALL
  SELECT 'zx81-machine', 'Storage', 'cassette', 40 UNION ALL
  SELECT 'abc-80-machine', 'Processor', 'Z80A @ 3 MHz', 10 UNION ALL
  SELECT 'abc-80-machine', 'Memory', '16 KB', 20 UNION ALL
  SELECT 'abc-80-machine', 'Video', '40x24 characters', 30 UNION ALL
  SELECT 'abc-80-machine', 'Storage', 'cassette, ABC 830 floppy', 40
) f JOIN hardware_models hm ON hm.slug = f.model;

INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, s.qty, s.note FROM (
  SELECT 'nes-toaster' AS model, 'cart' AS code, 1 AS qty, 'cartridge slot' AS note UNION ALL
  SELECT 'nes-toaster', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'nes-toaster', 'av', 1, 'video out' UNION ALL
  SELECT 'nes-toaster', 'psu', 1, 'power in' UNION ALL
  SELECT 'nes-toaster', 'exp', 1, 'expansion port, underneath' UNION ALL
  SELECT 'nes-top-loader', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'nes-top-loader', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'nes-top-loader', 'rf', 1, 'RF out' UNION ALL
  SELECT 'nes-top-loader', 'psu', 1, 'power in' UNION ALL
  SELECT 'snes-console', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'snes-console', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'snes-console', 'av', 1, 'video out' UNION ALL
  SELECT 'snes-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'snes-console', 'exp', 1, 'expansion port, underneath' UNION ALL
  SELECT 'n64-console', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'n64-console', 'ctrl', 4, 'controller ports' UNION ALL
  SELECT 'n64-console', 'exp', 1, 'memory expansion bay' UNION ALL
  SELECT 'n64-console', 'av', 1, 'multi out' UNION ALL
  SELECT 'n64-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'mega-drive-1', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'mega-drive-1', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'mega-drive-1', 'av', 1, 'video out' UNION ALL
  SELECT 'mega-drive-1', 'psu', 1, 'power in' UNION ALL
  SELECT 'mega-drive-1', 'exp', 1, 'expansion port, for the Mega-CD' UNION ALL
  SELECT 'mega-drive-2', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'mega-drive-2', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'mega-drive-2', 'av', 1, 'video out' UNION ALL
  SELECT 'mega-drive-2', 'psu', 1, 'power in' UNION ALL
  SELECT 'mega-drive-2', 'exp', 1, 'expansion port, for the Mega-CD' UNION ALL
  SELECT 'mega-cd-2', 'passthru', 1, 'the Mega Drive sits on top' UNION ALL
  SELECT 'mega-cd-2', 'cdport', 1, 'CD drive' UNION ALL
  SELECT 'mega-cd-2', 'memcard', 1, 'backup RAM cartridge slot' UNION ALL
  SELECT 'mega-cd-2', 'psu', 1, 'power in' UNION ALL
  SELECT 'saturn-console', 'cdport', 1, 'CD drive' UNION ALL
  SELECT 'saturn-console', 'cart', 1, 'cartridge slot, RAM and backup' UNION ALL
  SELECT 'saturn-console', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'saturn-console', 'memcard', 1, 'internal backup RAM' UNION ALL
  SELECT 'saturn-console', 'av', 1, 'AV out' UNION ALL
  SELECT 'saturn-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'dreamcast-console', 'cdport', 1, 'GD-ROM drive' UNION ALL
  SELECT 'dreamcast-console', 'ctrl', 4, 'controller ports' UNION ALL
  SELECT 'dreamcast-console', 'modem', 1, 'modem bay' UNION ALL
  SELECT 'dreamcast-console', 'av', 1, 'AV out' UNION ALL
  SELECT 'dreamcast-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'master-system-2', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'master-system-2', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'master-system-2', 'rf', 1, 'RF out' UNION ALL
  SELECT 'master-system-2', 'psu', 1, 'power in' UNION ALL
  SELECT 'playstation-scph1002', 'cdport', 1, 'CD drive' UNION ALL
  SELECT 'playstation-scph1002', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'playstation-scph1002', 'memcard', 2, 'memory card slots' UNION ALL
  SELECT 'playstation-scph1002', 'exp', 1, 'parallel port' UNION ALL
  SELECT 'playstation-scph1002', 'ser', 1, 'serial link port' UNION ALL
  SELECT 'playstation-scph1002', 'av', 1, 'AV multi out' UNION ALL
  SELECT 'playstation-scph1002', 'psu', 1, 'power in' UNION ALL
  SELECT 'atari-2600-vcs', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'atari-2600-vcs', 'ctrl', 2, 'joystick ports' UNION ALL
  SELECT 'atari-2600-vcs', 'rf', 1, 'RF out' UNION ALL
  SELECT 'atari-2600-vcs', 'psu', 1, 'power in' UNION ALL
  SELECT 'neo-geo-aes', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'neo-geo-aes', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'neo-geo-aes', 'memcard', 1, 'memory card slot' UNION ALL
  SELECT 'neo-geo-aes', 'av', 1, 'AV out' UNION ALL
  SELECT 'neo-geo-aes', 'psu', 1, 'power in' UNION ALL
  SELECT 'pc-engine-core', 'cart', 1, 'HuCard slot' UNION ALL
  SELECT 'pc-engine-core', 'exp', 1, 'expansion bus, for the CD-ROM unit' UNION ALL
  SELECT 'pc-engine-core', 'ctrl', 1, 'controller port' UNION ALL
  SELECT 'pc-engine-core', 'rf', 1, 'RF out' UNION ALL
  SELECT 'pc-engine-core', 'psu', 1, 'power in' UNION ALL
  SELECT 'intellivision-master', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'intellivision-master', 'ctrl', 2, 'hand controllers, hard-wired on early units' UNION ALL
  SELECT 'intellivision-master', 'exp', 1, 'expansion connector' UNION ALL
  SELECT 'intellivision-master', 'rf', 1, 'RF out' UNION ALL
  SELECT 'intellivision-master', 'psu', 1, 'power in' UNION ALL
  SELECT 'colecovision-console', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'colecovision-console', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'colecovision-console', 'exp', 1, 'expansion module connector' UNION ALL
  SELECT 'colecovision-console', 'rf', 1, 'RF out' UNION ALL
  SELECT 'colecovision-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'vectrex-console', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'vectrex-console', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'vectrex-console', 'psu', 1, 'power in' UNION ALL
  SELECT '3do-fz1', 'cdport', 1, 'CD drive' UNION ALL
  SELECT '3do-fz1', 'ctrl', 1, 'controller port, daisy chained' UNION ALL
  SELECT '3do-fz1', 'exp', 1, 'expansion bay' UNION ALL
  SELECT '3do-fz1', 'av', 1, 'AV out' UNION ALL
  SELECT '3do-fz1', 'psu', 1, 'power in' UNION ALL
  SELECT 'jaguar-console', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'jaguar-console', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'jaguar-console', 'exp', 1, 'expansion port, for the CD unit' UNION ALL
  SELECT 'jaguar-console', 'av', 1, 'AV out' UNION ALL
  SELECT 'jaguar-console', 'psu', 1, 'power in' UNION ALL
  SELECT 'cdi-910', 'cdport', 1, 'CD drive' UNION ALL
  SELECT 'cdi-910', 'ctrl', 2, 'controller ports' UNION ALL
  SELECT 'cdi-910', 'exp', 1, 'expansion bay, for the Digital Video cartridge' UNION ALL
  SELECT 'cdi-910', 'av', 1, 'AV out' UNION ALL
  SELECT 'cdi-910', 'psu', 1, 'power in' UNION ALL
  SELECT 'game-boy-pocket', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'game-boy-pocket', 'link', 1, 'link port' UNION ALL
  SELECT 'game-boy-pocket', 'psu', 1, 'power in' UNION ALL
  SELECT 'game-boy-color', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'game-boy-color', 'link', 1, 'link port' UNION ALL
  SELECT 'game-boy-color', 'psu', 1, 'power in' UNION ALL
  SELECT 'gba-original', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'gba-original', 'link', 1, 'link port' UNION ALL
  SELECT 'gba-original', 'psu', 1, 'power in' UNION ALL
  SELECT 'game-gear-handheld', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'game-gear-handheld', 'link', 1, 'gear-to-gear port' UNION ALL
  SELECT 'game-gear-handheld', 'psu', 1, 'power in' UNION ALL
  SELECT 'lynx-ii', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'lynx-ii', 'link', 1, 'ComLynx port' UNION ALL
  SELECT 'lynx-ii', 'psu', 1, 'power in' UNION ALL
  SELECT 'wonderswan-color', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'wonderswan-color', 'link', 1, 'link port' UNION ALL
  SELECT 'zx-spectrum-48k', 'edge', 1, 'rear expansion edge connector' UNION ALL
  SELECT 'zx-spectrum-48k', 'tape', 1, 'EAR and MIC' UNION ALL
  SELECT 'zx-spectrum-48k', 'misc', 1, 'TV out' UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'edge', 1, 'rear expansion edge connector' UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'joy', 2, 'Sinclair joystick ports' UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'ay', 1, 'AY sound chip' UNION ALL
  SELECT 'zx-spectrum-128-plus2', 'misc', 1, 'RGB and TV out' UNION ALL
  SELECT 'atari-520st', 'floppy', 1, 'external floppy port' UNION ALL
  SELECT 'atari-520st', 'midi', 2, 'MIDI in and out' UNION ALL
  SELECT 'atari-520st', 'acsi', 1, 'ACSI/DMA port' UNION ALL
  SELECT 'atari-520st', 'cart', 1, 'ROM cartridge port' UNION ALL
  SELECT 'atari-520st', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'atari-520st', 'par', 1, 'parallel port' UNION ALL
  SELECT 'atari-520st', 'ser', 1, 'serial port' UNION ALL
  SELECT 'atari-1040stf', 'floppy', 1, 'internal drive, external port' UNION ALL
  SELECT 'atari-1040stf', 'midi', 2, 'MIDI in and out' UNION ALL
  SELECT 'atari-1040stf', 'acsi', 1, 'ACSI/DMA port' UNION ALL
  SELECT 'atari-1040stf', 'cart', 1, 'ROM cartridge port' UNION ALL
  SELECT 'atari-1040stf', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'atari-1040stf', 'par', 1, 'parallel port' UNION ALL
  SELECT 'atari-1040stf', 'ser', 1, 'serial port' UNION ALL
  SELECT 'atari-mega-st', 'stbus', 1, 'internal expansion bus' UNION ALL
  SELECT 'atari-mega-st', 'floppy', 1, 'internal drive' UNION ALL
  SELECT 'atari-mega-st', 'midi', 2, 'MIDI in and out' UNION ALL
  SELECT 'atari-mega-st', 'acsi', 1, 'ACSI/DMA port' UNION ALL
  SELECT 'atari-mega-st', 'cart', 1, 'ROM cartridge port' UNION ALL
  SELECT 'atari-mega-st', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'atari-mega-st', 'par', 1, 'parallel port' UNION ALL
  SELECT 'atari-mega-st', 'ser', 1, 'serial port' UNION ALL
  SELECT 'amstrad-cpc-464', 'edge', 1, 'expansion edge connector' UNION ALL
  SELECT 'amstrad-cpc-464', 'joy', 1, 'joystick port' UNION ALL
  SELECT 'amstrad-cpc-464', 'printer', 1, 'printer port' UNION ALL
  SELECT 'amstrad-cpc-464', 'misc', 1, 'monitor connector' UNION ALL
  SELECT 'amstrad-cpc-6128', 'edge', 1, 'expansion edge connector' UNION ALL
  SELECT 'amstrad-cpc-6128', 'floppy', 1, 'second drive port' UNION ALL
  SELECT 'amstrad-cpc-6128', 'joy', 1, 'joystick port' UNION ALL
  SELECT 'amstrad-cpc-6128', 'printer', 1, 'printer port' UNION ALL
  SELECT 'amstrad-cpc-6128', 'misc', 1, 'monitor connector' UNION ALL
  SELECT 'msx2-machine', 'cart', 2, 'cartridge slots' UNION ALL
  SELECT 'msx2-machine', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'apple-iie', 'aslot', 7, 'expansion slots' UNION ALL
  SELECT 'apple-iie', 'misc', 1, 'auxiliary slot' UNION ALL
  SELECT 'bbc-micro-b', 'tube', 1, 'Tube second-processor interface' UNION ALL
  SELECT 'bbc-micro-b', 'onemhz', 1, '1 MHz bus' UNION ALL
  SELECT 'bbc-micro-b', 'userport', 1, 'user port' UNION ALL
  SELECT 'bbc-micro-b', 'econet', 1, 'Econet socket' UNION ALL
  SELECT 'bbc-micro-b', 'edge', 1, 'expansion connectors' UNION ALL
  SELECT 'acorn-electron-machine', 'edge', 1, 'expansion connector' UNION ALL
  SELECT 'acorn-electron-machine', 'misc', 1, 'TV and monitor out' UNION ALL
  SELECT 'archimedes-a3000', 'podule', 1, 'internal podule slot' UNION ALL
  SELECT 'archimedes-a3000', 'floppy', 1, 'internal drive' UNION ALL
  SELECT 'archimedes-a3000', 'misc', 1, 'expansion connector' UNION ALL
  SELECT 'atari-800xl', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'atari-800xl', 'pbi', 1, 'parallel bus interface' UNION ALL
  SELECT 'atari-800xl', 'sio', 1, 'SIO daisy chain' UNION ALL
  SELECT 'atari-800xl', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'atari-130xe', 'cart', 1, 'cartridge slot' UNION ALL
  SELECT 'atari-130xe', 'eci', 1, 'enhanced cartridge interface' UNION ALL
  SELECT 'atari-130xe', 'sio', 1, 'SIO daisy chain' UNION ALL
  SELECT 'atari-130xe', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'mac-plus', 'simm', 4, 'SIMM sockets' UNION ALL
  SELECT 'mac-plus', 'scsi', 1, 'SCSI port' UNION ALL
  SELECT 'mac-plus', 'floppy', 1, 'external floppy port' UNION ALL
  SELECT 'mac-plus', 'ser', 2, 'printer and modem ports' UNION ALL
  SELECT 'x68000-expert', 'floppy', 2, 'internal drives' UNION ALL
  SELECT 'x68000-expert', 'scsi', 1, 'SASI/SCSI' UNION ALL
  SELECT 'x68000-expert', 'misc', 1, 'expansion slots' UNION ALL
  SELECT 'pc-9801-vx', 'misc', 2, 'C-bus expansion slots' UNION ALL
  SELECT 'pc-9801-vx', 'floppy', 2, 'internal drives' UNION ALL
  SELECT 'pc-9801-vx', 'ser', 1, 'serial port' UNION ALL
  SELECT 'pc-9801-vx', 'par', 1, 'printer port' UNION ALL
  SELECT 'trs-80-model-1', 'misc', 1, 'expansion interface connector' UNION ALL
  SELECT 'trs-80-model-1', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'dragon-32-machine', 'cart', 1, 'cartridge port' UNION ALL
  SELECT 'dragon-32-machine', 'joy', 2, 'joystick ports' UNION ALL
  SELECT 'dragon-32-machine', 'ser', 1, 'serial printer port' UNION ALL
  SELECT 'oric-atmos', 'edge', 1, 'expansion connector' UNION ALL
  SELECT 'oric-atmos', 'tape', 1, 'cassette port' UNION ALL
  SELECT 'oric-atmos', 'misc', 1, 'printer port' UNION ALL
  SELECT 'sam-coupe-machine', 'edge', 1, 'expansion connector' UNION ALL
  SELECT 'sam-coupe-machine', 'floppy', 2, 'internal drive bays' UNION ALL
  SELECT 'sam-coupe-machine', 'joy', 1, 'joystick port' UNION ALL
  SELECT 'sam-coupe-machine', 'misc', 1, 'MIDI and network' UNION ALL
  SELECT 'sinclair-ql-machine', 'edge', 1, 'expansion connector' UNION ALL
  SELECT 'sinclair-ql-machine', 'ser', 2, 'serial ports' UNION ALL
  SELECT 'sinclair-ql-machine', 'misc', 1, 'Microdrive expansion and network' UNION ALL
  SELECT 'zx81-machine', 'edge', 1, 'rear edge connector' UNION ALL
  SELECT 'zx81-machine', 'tape', 1, 'EAR and MIC' UNION ALL
  SELECT 'zx81-machine', 'misc', 1, 'TV out' UNION ALL
  SELECT 'abc-80-machine', 'misc', 1, 'ABC bus expansion' UNION ALL
  SELECT 'abc-80-machine', 'ser', 1, 'serial port' UNION ALL
  SELECT 'abc-80-machine', 'tape', 1, 'cassette port'
) s
  JOIN hardware_models hm ON hm.slug = s.model
  JOIN platforms p        ON p.id = hm.platform_id
  JOIN hardware_vocab hv  ON hv.code = s.code
                         AND hv.platform_id IN (0, p.id)
  LEFT JOIN hardware_vocab own ON own.code = s.code AND own.platform_id = p.id
  WHERE hv.platform_id = COALESCE(own.platform_id, 0);

-- ---------------------------------------------------------------------------
-- The rest of the software models
--
-- Generated from starter-data/software_models.json, same rule as above.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'pc'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'PC MS-DOS game, big box', 'pc-dos-floppy-bigbox', '3.5-inch disk',
       1988, 'The DOS big box: a card box far larger than its contents, disks, a manual, and whatever the copy protection needed that year.', 10;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Disks', '3 x 3.5-inch HD', 'How many, and what size — 5.25-inch on earlier releases', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'DOS version', '5.0', 'The minimum the box claims', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Memory', '640 KB conventional', 'Conventional, EMS or XMS as the box states it', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Sound cards', 'Sound Blaster, Ad Lib, PC speaker', 'What the installer offers', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Copy protection', 'manual lookup', 'Manual lookup, code wheel, keydisk, none', 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Installed size', '12 MB', NULL, 60
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card, and mostly air', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disks', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Reference card', 'Keyboard commands, usually', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Code wheel or feelie', 'The bigger publishers', 60
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-dos-floppy-bigbox';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'pc'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'PC Windows 9x game, jewel case', 'pc-win9x-cdrom-jewel', 'CD-ROM',
       1997, 'The shape releases took once the big box was retired: a jewel case, one CD, and a manual folded into the tray.', 20;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Discs', '1 x CD-ROM', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Windows version', '95 or 98', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'DirectX', '6.0', 'The version on the disc', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, '3D acceleration', 'Direct3D or Glide', 'Software only, Direct3D, Glide, or a choice', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Installed size', '300 MB', NULL, 50
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'CD key', 'on the case', 'Where the key was printed, if there was one', 60
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Jewel case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disc', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', 'Often a booklet in the tray', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'CD key', 'Printed on the case or the sleeve', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'pc-win9x-cdrom-jewel';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'atari-st'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Atari ST boxed game, 3.5-inch', 'atari-st-boxed-game-disk', '3.5-inch disk',
       1985, 'The ST equivalent of the Amiga box, and often the same game in a different sleeve: a card box, single-sided or double-sided disks, a manual.', 30;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Disks', '1 x 3.5-inch DS', 'Single or double sided — early ST disks are single', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Memory', '512 KB', '520ST or 1040ST', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Copy protection', 'manual lookup', 'Manual lookup, code wheel, custom format, none', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Hard drive installable', 'no', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Colour or mono', 'colour', 'Some applications are mono monitor only', 50
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Language', 'English', NULL, 60
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card, usually', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disks', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Poster or map', 'Bigger releases only', 50
  FROM software_models WHERE library_id IS NULL AND slug = 'atari-st-boxed-game-disk';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'c64'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'C64 game, cassette', 'c64-cassette-game', 'cassette',
       1982, 'The budget shape, and how most C64 games were actually bought: a cassette in a library case, loaded with a counter and hope.', 40;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Tapes', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Loader', 'Novaload', 'Novaload, Turbo, standard, or the publisher''s own', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Sides', 'one', 'Some releases put a second game or a demo on side B', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Language', 'English', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Library case', 'The clear plastic hinged case', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cassette', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Inlay card', 'Folded, with the instructions on the inside', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cassette-game';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'c64'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'C64 game, 5.25-inch disk', 'c64-disk-game', '5.25-inch disk',
       1983, 'The disk release: a card box or a folder, one or two 5.25-inch disks, flipped over for side B as often as not.', 50;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Disks', '1 x 5.25-inch', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Sides used', 'both', 'A single-sided drive reading a flippy is two sides of one disk', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Copy protection', 'custom format', 'Custom format, manual lookup, none', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Fast loader', 'yes', 'Whether it carries its own', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box or folder', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disks', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-disk-game';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'c64'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'C64 cartridge', 'c64-cartridge', 'cartridge',
       1982, 'Instant loading and no piracy, which is why publishers liked them and buyers did not — they cost three times a cassette.', 60;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridge', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Bank switching', 'none', 'Plain 8/16 KB, or a banked type such as Ocean or System 3', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', 'Often a single folded sheet', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'c64-cartridge';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'zx-spectrum'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'ZX Spectrum game, cassette', 'zx-spectrum-cassette', 'cassette',
       1982, 'The dominant British shape: a cassette in a library case, and a loading screen drawn a line at a time while you waited.', 70;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Tapes', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Model', '48K', '48K, 128K, or both on one tape', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Loader', 'standard', 'Standard ROM loader, Speedlock, or the publisher''s own', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Language', 'English', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Library case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cassette', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Inlay card', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'zx-spectrum-cassette';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'amstrad-cpc'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Amstrad CPC game, cassette', 'amstrad-cpc-cassette', 'cassette',
       1984, 'The 464''s format, and the one most CPC software shipped on even after the 6128 arrived.', 80;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Tapes', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Memory', '64 KB', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Loader', 'standard', 'Standard, Speedlock, or the publisher''s own', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Library case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cassette', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Inlay card', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amstrad-cpc-cassette';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'msx'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'MSX cartridge', 'msx-cartridge', 'cartridge',
       1983, 'The MSX standard meant one cartridge ran on a Sony, a Philips or a Panasonic, which almost nothing else of the era could claim.', 90;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridge', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Standard', 'MSX', 'MSX, MSX2, MSX2+ or turboR', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Sound chip', 'PSG', 'PSG, or SCC and FM-PAC where the cartridge carries one', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'Japan', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card or clamshell', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'msx-cartridge';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'nes'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'NES boxed cartridge', 'nes-cart-game', 'cartridge',
       1985, 'A card box, a cartridge in a dust sleeve, and a manual — the shape almost every console followed afterwards.', 100;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridges', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Mapper', 'MMC1', 'The board''s mapper, where it is known', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL A', 'NTSC, PAL A or PAL B', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Battery save', 'no', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Dust sleeve', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Poster or insert', 'Bigger releases only', 50
  FROM software_models WHERE library_id IS NULL AND slug = 'nes-cart-game';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'snes'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Super Nintendo boxed cartridge', 'snes-cart-game', 'cartridge',
       1990, 'Card box, cartridge, manual. The PAL cartridge is a different shape from the Japanese one, which is a lockout rather than an accident.', 110;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridges', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Enhancement chip', 'none', 'DSP-1, SA-1, Super FX, or none', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Battery save', 'yes', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Box', 'Card', 10
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Insert', 'Poster, map or advertising', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'snes-cart-game';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'master-system'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Master System boxed cartridge', 'master-system-cart', 'cartridge',
       1985, 'Sega''s clamshell case rather than a card box, which is why so many more of them survive intact.', 120;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Cartridges', '1', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'FM sound', 'no', 'Japanese machines only', 30
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Clamshell case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Cartridge', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'master-system-cart';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'playstation'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'PlayStation game, jewel case', 'playstation-cd-jewel', 'CD-ROM',
       1995, 'A double-height jewel case, a black-bottomed disc, and a manual. The case hinges are what break.', 130;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Discs', '1 x CD-ROM', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Serial', 'SLES-00000', 'The SLES, SLUS or SLPS number on the disc', 20
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Region', 'PAL', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Memory card blocks', '1', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Jewel case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disc', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Registration card', NULL, 40
  FROM software_models WHERE library_id IS NULL AND slug = 'playstation-cd-jewel';

INSERT IGNORE INTO software_models
    (library_id, platform_id, category_id, name, slug, media, year_from, notes, sort_order)
SELECT NULL,
       (SELECT id FROM platforms  WHERE library_id IS NULL AND slug = 'cd32'),
       (SELECT id FROM categories WHERE library_id IS NULL AND slug = 'games'),
       'Amiga CD32 game, jewel case', 'amiga-cd32-cd', 'CD-ROM',
       1993, 'Usually an A1200 game on a disc, sometimes with the video and audio the CD made room for.', 140;
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Discs', '1 x CD-ROM', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Kickstart', '3.1', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Memory', '2 MB chip', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_fields (model_id, label, default_value, hint, sort_order)
SELECT id, 'Save to', 'internal flash', 'Internal flash memory, or the FMV cartridge', 40
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Jewel case', NULL, 10
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Disc', NULL, 20
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';
INSERT IGNORE INTO software_model_contents (model_id, label, note, sort_order)
SELECT id, 'Manual', NULL, 30
  FROM software_models WHERE library_id IS NULL AND slug = 'amiga-cd32-cd';


-- ---------------------------------------------------------------------------
-- Connectors for the platforms that had none
--
-- Eight platforms carried no vocabulary at all, so a machine on one of them could
-- declare no slot that resolved and came out able to hold nothing - which the seed
-- suite catches as "every machine has at least one slot". Generated from
-- starter-data/hardware_specifications.json, same rule as everything else here.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'cart', 'Cartridge port', 10 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'wonderswan';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'link', 'Link port', 20 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'wonderswan';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 30 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'x68000';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 40 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'pc-9801';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 50 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'trs-80';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'tape', 'Cassette port', 60 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'trs-80';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'cart', 'Cartridge port', 70 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'dragon-32';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'joy', 'Control port', 80 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'dragon-32';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'edge', 'Expansion edge connector', 90 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'oric';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'tape', 'Cassette port', 100 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'oric';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 110 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'oric';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'edge', 'Expansion edge connector', 120 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'sinclair-ql';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 130 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'sinclair-ql';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'misc', 'Miscellaneous', 140 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'abc-80';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'tape', 'Cassette port', 150 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'abc-80';

-- Atari 7800, missed by the generator: its slug is also a platform slug, so the
-- plain "is this already in the file" search found the platform and skipped the model.
INSERT IGNORE INTO hardware_models (vendor_id, platform_id, category_id, name, slug, year_from, notes, sort_order)
SELECT v.id, p.id, c.id, 'Atari 7800', 'atari-7800', 1986, 'Plays 2600 cartridges as well, which almost nothing else of its generation could say.', 610
  FROM platforms p JOIN categories c ON c.slug = 'console'
  LEFT JOIN companies v ON v.slug = 'atari' AND v.library_id IS NULL
  WHERE p.slug = 'atari-7800' AND p.library_id IS NULL;
INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT id, 'Processor', 'Atari SALLY 6502 @ 1.79 MHz', 10 FROM hardware_models WHERE slug = 'atari-7800' AND library_id IS NULL;
INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT id, 'Memory', '4 KB', 20 FROM hardware_models WHERE slug = 'atari-7800' AND library_id IS NULL;
INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT id, 'Video', 'MARIA', 30 FROM hardware_models WHERE slug = 'atari-7800' AND library_id IS NULL;
INSERT IGNORE INTO model_fields (model_id, label, default_value, sort_order)
SELECT id, 'Sound', 'TIA, POKEY in some cartridges', 40 FROM hardware_models WHERE slug = 'atari-7800' AND library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'cartridge slot' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'cart' AND hv.platform_id = p.id
  WHERE hm.slug = 'atari-7800' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 2, 'controller ports' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'ctrl' AND hv.platform_id = p.id
  WHERE hm.slug = 'atari-7800' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'expansion connector' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'exp' AND hv.platform_id = p.id
  WHERE hm.slug = 'atari-7800' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'RF out' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'rf' AND hv.platform_id = p.id
  WHERE hm.slug = 'atari-7800' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'power in' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'psu' AND hv.platform_id = p.id
  WHERE hm.slug = 'atari-7800' AND hm.library_id IS NULL;

-- ---------------------------------------------------------------------------
-- Slots for the three machines whose connectors are defined further up this file
--
-- Order matters in a file that is executed top to bottom. Their platforms had no
-- vocabulary until the block above, and their model_slots insert ran before it -
-- so the join matched nothing and three machines came out able to hold nothing.
-- Re-run here, after the connectors exist. INSERT IGNORE, so this is a no-op for
-- anything already written.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'cartridge slot' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'cart' AND hv.platform_id = p.id
  WHERE hm.slug = 'wonderswan-color' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'link port' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'link' AND hv.platform_id = p.id
  WHERE hm.slug = 'wonderswan-color' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'expansion interface connector' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'misc' AND hv.platform_id = p.id
  WHERE hm.slug = 'trs-80-model-1' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'cassette port' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'tape' AND hv.platform_id = p.id
  WHERE hm.slug = 'trs-80-model-1' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'expansion connector' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'edge' AND hv.platform_id = p.id
  WHERE hm.slug = 'oric-atmos' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'cassette port' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'tape' AND hv.platform_id = p.id
  WHERE hm.slug = 'oric-atmos' AND hm.library_id IS NULL;
INSERT IGNORE INTO model_slots (model_id, vocab_id, quantity, notes)
SELECT hm.id, hv.id, 1, 'printer port' FROM hardware_models hm
  JOIN platforms p ON p.id = hm.platform_id
  JOIN hardware_vocab hv ON hv.code = 'misc' AND hv.platform_id = p.id
  WHERE hm.slug = 'oric-atmos' AND hm.library_id IS NULL;

-- Connectors a machine names on a platform that had not defined them.
-- The 0 sentinel in hardware_vocab holds features - Processor, Memory, SCSI
-- controller - not ports, so a slot resolving to it pointed at the wrong kind of
-- thing entirely. Every connector a machine claims is now a real interface on its
-- own platform. Generated from starter-data/hardware_specifications.json.
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 10 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'playstation';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'floppy', 'Floppy port', 20 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'archimedes';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'floppy', 'Floppy port', 30 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'mac-68k';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 40 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'mac-68k';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'floppy', 'Floppy port', 50 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'x68000';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'scsi', 'SCSI port', 60 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'x68000';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'floppy', 'Floppy port', 70 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'pc-9801';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 80 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'pc-9801';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'par', 'Parallel port', 90 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'pc-9801';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 100 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'dragon-32';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'floppy', 'Floppy port', 110 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'sam-coupe';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 120 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'sinclair-ql';
INSERT IGNORE INTO hardware_vocab (kind, platform_id, code, name, sort_order)
SELECT 'interface', p.id, 'ser', 'Serial port', 130 FROM platforms p
  WHERE p.library_id IS NULL AND p.slug = 'abc-80';

-- Repoint any slot that had landed on a feature row at its platform's own port.
UPDATE model_slots ms
  JOIN hardware_models hm ON hm.id = ms.model_id
  JOIN hardware_vocab old ON old.id = ms.vocab_id
  JOIN hardware_vocab fixed ON fixed.code = old.code
                          AND fixed.platform_id = hm.platform_id
                          AND fixed.kind = 'interface'
   SET ms.vocab_id = fixed.id
 WHERE old.kind <> 'interface';
