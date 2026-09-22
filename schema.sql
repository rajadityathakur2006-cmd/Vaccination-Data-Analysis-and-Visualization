-- ============================================================================
-- Vaccination Data Analysis - Normalized SQL Schema
-- ============================================================================
-- Covers all 5 tables named in the project brief. Tables 1, 2, 4, 5 are
-- populated from the source files actually provided for this submission.
-- Table 3 (reported_cases) is defined here to keep the schema complete and
-- ready for that file, but was NOT populated -- that data was not provided.
-- See the notebook's data-wrangling section for the cleaning steps applied
-- before loading (drop footer row, cast YEAR to int, filter to country-level
-- rows where relevant).
-- ============================================================================

CREATE TABLE countries (
    iso3_code       CHAR(3) PRIMARY KEY,
    country_name    VARCHAR(100) NOT NULL,
    who_region      VARCHAR(10)
);

CREATE TABLE antigens (
    antigen_code        VARCHAR(20) PRIMARY KEY,
    antigen_description VARCHAR(200) NOT NULL
);

CREATE TABLE diseases (
    disease_code        VARCHAR(30) PRIMARY KEY,
    disease_description VARCHAR(200) NOT NULL
);

-- ----------------------------------------------------------------------------
-- Table 1: Coverage data  (source: coverage-data.xlsx)
-- ----------------------------------------------------------------------------
CREATE TABLE coverage (
    coverage_id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_type               VARCHAR(30) NOT NULL,      -- COUNTRIES / WHO_REGIONS / GLOBAL / etc.
    iso3_code                CHAR(3),                    -- NULL for non-country GROUP rows
    country_or_group_name    VARCHAR(100) NOT NULL,
    year                      SMALLINT NOT NULL,
    antigen_code              VARCHAR(20) NOT NULL,
    coverage_category         VARCHAR(20) NOT NULL,      -- ADMIN / OFFICIAL / WUENIC / HPV / PAB
    coverage_category_desc    VARCHAR(100),
    target_number              BIGINT,
    doses                       BIGINT,
    coverage_pct                 DECIMAL(5,2),
    FOREIGN KEY (iso3_code) REFERENCES countries(iso3_code),
    FOREIGN KEY (antigen_code) REFERENCES antigens(antigen_code),
    UNIQUE KEY uq_coverage (group_type, iso3_code, year, antigen_code, coverage_category)
);
CREATE INDEX idx_coverage_country_year ON coverage(iso3_code, year);
CREATE INDEX idx_coverage_antigen ON coverage(antigen_code);

-- ----------------------------------------------------------------------------
-- Table 2: Incidence rate data  (source: incidence-rate-data.xlsx)
-- ----------------------------------------------------------------------------
CREATE TABLE incidence_rate (
    incidence_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_type          VARCHAR(30) NOT NULL,
    iso3_code            CHAR(3),
    country_or_group_name VARCHAR(100) NOT NULL,
    year                   SMALLINT NOT NULL,
    disease_code            VARCHAR(30) NOT NULL,
    denominator               VARCHAR(60) NOT NULL,     -- e.g. 'per 1,000,000 total population'
    incidence_rate              DECIMAL(12,4),
    FOREIGN KEY (iso3_code) REFERENCES countries(iso3_code),
    FOREIGN KEY (disease_code) REFERENCES diseases(disease_code),
    UNIQUE KEY uq_incidence (group_type, iso3_code, year, disease_code)
);
CREATE INDEX idx_incidence_country_year ON incidence_rate(iso3_code, year);
CREATE INDEX idx_incidence_disease ON incidence_rate(disease_code);

-- ----------------------------------------------------------------------------
-- Table 3: Reported cases  (source file NOT provided -- schema only, unpopulated)
-- ----------------------------------------------------------------------------
CREATE TABLE reported_cases (
    case_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    group_type     VARCHAR(30) NOT NULL,
    iso3_code       CHAR(3),
    country_or_group_name VARCHAR(100) NOT NULL,
    year             SMALLINT NOT NULL,
    disease_code       VARCHAR(30) NOT NULL,
    cases                BIGINT,
    FOREIGN KEY (iso3_code) REFERENCES countries(iso3_code),
    FOREIGN KEY (disease_code) REFERENCES diseases(disease_code),
    UNIQUE KEY uq_reported_cases (group_type, iso3_code, year, disease_code)
);
CREATE INDEX idx_reportedcases_country_year ON reported_cases(iso3_code, year);

-- ----------------------------------------------------------------------------
-- Table 4: Vaccine introduction  (source: vaccine-introduction-data.xlsx)
-- ----------------------------------------------------------------------------
CREATE TABLE vaccine_introduction (
    intro_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    iso3_code     CHAR(3) NOT NULL,
    year           SMALLINT NOT NULL,
    vaccine_description VARCHAR(150) NOT NULL,
    intro_status          VARCHAR(20) NOT NULL,   -- Yes / No / Yes (R) / Yes (P) / High risk area / ND / ...
    FOREIGN KEY (iso3_code) REFERENCES countries(iso3_code),
    UNIQUE KEY uq_intro (iso3_code, year, vaccine_description)
);
CREATE INDEX idx_intro_country_year ON vaccine_introduction(iso3_code, year);

-- ----------------------------------------------------------------------------
-- Table 5: Vaccine schedule  (source: vaccine-schedule-data.xlsx)
-- ----------------------------------------------------------------------------
CREATE TABLE vaccine_schedule (
    schedule_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    iso3_code          CHAR(3) NOT NULL,
    year                 SMALLINT NOT NULL,
    vaccine_code           VARCHAR(20) NOT NULL,
    vaccine_description       VARCHAR(200) NOT NULL,
    schedule_round               SMALLINT NOT NULL,
    target_pop                     VARCHAR(60),
    target_pop_description            VARCHAR(150),
    geoarea                              VARCHAR(30),
    age_administered                       VARCHAR(30),
    source_comment                           VARCHAR(200),
    FOREIGN KEY (iso3_code) REFERENCES countries(iso3_code),
    UNIQUE KEY uq_schedule (iso3_code, year, vaccine_code, schedule_round)
);
CREATE INDEX idx_schedule_country_year ON vaccine_schedule(iso3_code, year);

-- ============================================================================
-- Notes on data-cleaning decisions this schema encodes (see notebook for detail):
--   1. Every source file has a trailing "Created: [timestamp]" export-stamp
--      row with a NULL year -- this must be excluded on load, not inserted.
--   2. coverage.coverage_category has three overlapping measurement methods
--      (ADMIN/OFFICIAL/WUENIC) for the same country/antigen/year -- callers
--      must filter to a single category (WUENIC recommended) for trend work
--      rather than averaging across methods.
--   3. group_type distinguishes country-level rows from regional/global
--      rollups already present in the source files -- filter to
--      group_type = 'COUNTRIES' for country-level analysis.
-- ============================================================================
