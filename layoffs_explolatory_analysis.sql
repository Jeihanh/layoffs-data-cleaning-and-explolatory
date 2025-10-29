/********************************************************************************************
 Project: Layoffs Data Exploration
 Author: Jeihan Ivan Hadar 
 Description:
     Exploratory Data Analysis (EDA) on the cleaned layoffs dataset.
     This script analyzes:
         1. Overall statistics and key figures
         2. Trends over time
         3. Insights by company, country, and stage
         4. Ranking of top affected companies per year
********************************************************************************************/

-- Preview cleaned dataset
SELECT *
FROM layoffs_staging2;


/********************************************
 1. BASIC STATISTICS
********************************************/

-- Maximum layoffs and layoff percentages
SELECT 
    MAX(total_laid_off) AS max_total_laid_off, 
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;

-- Companies with 100% layoffs (fully laid off)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Total layoffs by company
SELECT 
    company, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- Date range of dataset
SELECT 
    MIN(`date`) AS start_date, 
    MAX(`date`) AS end_date
FROM layoffs_staging2;


/********************************************
 2. AGGREGATION BY COUNTRY, STAGE, AND YEAR
********************************************/

-- Total layoffs by country
SELECT 
    country, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Total layoffs by company stage
SELECT 
    stage, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;

-- Total layoffs by year
SELECT 
    YEAR(`date`) AS year, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY year ASC;


/********************************************
 3. AVERAGE IMPACT ANALYSIS
********************************************/

-- Average percentage of workforce laid off by company
SELECT 
    company, 
    AVG(percentage_laid_off) AS avg_percentage_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY avg_percentage_laid_off DESC;


/********************************************
 4. MONTHLY AND ROLLING LAYOFF TRENDS
********************************************/

-- Total layoffs per month
SELECT 
    DATE_FORMAT(`date`, '%Y-%m') AS month, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY month
ORDER BY month ASC;

-- Rolling cumulative layoffs over time
WITH Monthly_Totals AS (
    SELECT 
        DATE_FORMAT(`date`, '%Y-%m') AS month, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL
    GROUP BY month
)
SELECT 
    month,
    total_laid_off,
    SUM(total_laid_off) OVER (ORDER BY month) AS rolling_total
FROM Monthly_Totals
ORDER BY month ASC;


/********************************************
 5. YEARLY COMPANY RANKINGS
********************************************/

-- Top 5 companies with the most layoffs per year
WITH Company_Year AS (
    SELECT 
        company, 
        YEAR(`date`) AS year, 
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
    SELECT 
        *,
        DENSE_RANK() OVER (
            PARTITION BY year 
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM Company_Year
    WHERE year IS NOT NULL
)
SELECT 
    company,
    year,
    total_laid_off,
    ranking
FROM Company_Year_Rank
WHERE ranking <= 5
ORDER BY year DESC, ranking ASC;


/********************************************************************************************
 End of Exploratory Data Analysis Script
********************************************************************************************/
