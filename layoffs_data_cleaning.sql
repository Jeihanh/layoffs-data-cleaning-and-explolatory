/********************************************************************************************
 Project: Layoffs Data Cleaning
 Author: Jeihan Ivan Hadar 
 Description:
     This script performs data cleaning operations on the 'layoffs' dataset.
     The process includes:
         1. Removing duplicates
         2. Standardizing values
         3. Handling null or blank values
         4. Removing unnecessary columns
********************************************************************************************/

-- Preview raw data
SELECT * 
FROM layoffs;

/********************************************
 1. CREATE STAGING TABLE
********************************************/

-- Create a copy of the raw table to preserve original data
CREATE TABLE layoffs_staging LIKE layoffs;

-- Insert all records into the staging table
INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

/********************************************
 2. IDENTIFY AND REMOVE DUPLICATES
********************************************/

-- Create a new staging table with a row number for duplicate detection
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
);

-- Insert data with a row number partitioned by key identifying fields
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company,
                        location,
                        industry,
                        total_laid_off,
                        percentage_laid_off,
                        `date`,
                        stage,
                        country,
                        funds_raised_millions
           ORDER BY company
       ) AS row_num
FROM layoffs_staging;

-- Remove duplicate rows (keep only first occurrence)
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

/********************************************
 3. STANDARDIZE TEXT DATA
********************************************/

-- Trim extra spaces from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names (e.g., "Crypto Currency", "Crypto.com" → "Crypto")
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Clean up country field (remove trailing periods, standardize naming)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

/********************************************
 4. FORMAT DATE FIELD
********************************************/

-- Convert 'date' column to proper DATE format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modify the column type to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

/********************************************
 5. HANDLE NULL OR BLANK VALUES
********************************************/

-- Convert empty strings in 'industry' to NULL
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

-- Fill missing industry values using other rows with the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Delete rows where both total_laid_off and percentage_laid_off are NULL
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

/********************************************
 6. FINAL CLEANUP
********************************************/

-- Drop helper column used for duplicate detection
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final clean dataset
SELECT * 
FROM layoffs_staging2;

/********************************************************************************************
 End of Data Cleaning Script
********************************************************************************************/
