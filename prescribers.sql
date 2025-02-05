-- a. Which prescriber had the highest total number of claims (totaled over all drugs)?
-- Report the npi and the total number of claims.
--1881634483, 99707
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;

-- b. Repeat the above, but this time report the nppes_provider_first_name,
-- nppes_provider_last_org_name, specialty_description, and the total number of claims.
--Bruce Pendley Family Practice
SELECT p.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, 
       pr.specialty_description, SUM(p.total_claim_count) AS total_claims
FROM prescription p
JOIN prescriber pr ON p.npi = pr.npi
GROUP BY p.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, pr.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
--Family Practice 975237
SELECT pr.specialty_description, SUM(p.total_claim_count) AS total_claims
FROM prescription p
JOIN prescriber pr ON p.npi = pr.npi
GROUP BY pr.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- Which specialty had the most total number of claims for opioids?
--Nurse Practioner 900845
SELECT pr.specialty_description, SUM(p.total_claim_count) AS total_claims
FROM prescription p
JOIN prescriber pr ON p.npi = pr.npi
JOIN drug d ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY pr.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table
-- that have no associated prescriptions in the prescription table?

SELECT DISTINCT pr.specialty_description
FROM prescriber pr
LEFT JOIN prescription p ON pr.npi = p.npi
WHERE p.npi IS NULL;

-- 3.a. Which drug (generic_name) had the highest total drug cost?
--Insulin Glargine, HUM.REC.ANLOG 104264066.35
SELECT d.generic_name, SUM(p.total_drug_cost) AS total_cost
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY total_cost DESC
LIMIT 1;

-- b. Which drug (generic_name) has the hightest total cost per day? 
--C1 Esterase Inhibitor 3495.22

SELECT d.generic_name, 
       SUM(p.total_drug_cost) / SUM(p.total_day_supply) AS total_cost_per_day
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.generic_name
HAVING SUM(p.total_day_supply) > 0  -- Ensure no division by zero
ORDER BY total_cost_per_day DESC
LIMIT 1;

-- rounded

SELECT d.generic_name, 
       ROUND(SUM(p.total_drug_cost) / SUM(p.total_day_supply), 2) AS total_cost_per_day
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.generic_name
HAVING SUM(p.total_day_supply) > 0
ORDER BY total_cost_per_day DESC
LIMIT 1;

-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' 
-- for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag
-- = 'Y', and says 'neither' for all other drugs.

SELECT d.drug_name,
       CASE
           WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
           WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
           ELSE 'neither'
       END AS drug_type
FROM drug d;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
-- Hint: Format the total costs as MONEY for easier comparision.
--more on opioids
SELECT 
    CASE
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    SUM(p.total_drug_cost) AS total_cost
FROM drug d
JOIN prescription p ON d.drug_name = p.drug_name
GROUP BY drug_type
ORDER BY SUM(p.total_drug_cost) DESC;

-- 5a. How many CBSAs are in Tennessee?
-- Warning: The cbsa table contains information for all states, not just Tennessee.
--6

SELECT COUNT(DISTINCT CBSA) AS num_cbsas_in_tennessee
FROM CBSA
WHERE cbsaname LIKE '% TN';

-- b. Which cbsa has the largest combined population? Which has the smallest?
-- Report the CBSA name and total population.
--largest is nashville-davidson-murfeesboro-franklin,tn 1830410
--smallest is morristown, tn 116352

SELECT cb.cbsaname, SUM(p.population) AS total_population
FROM CBSA cb
JOIN fips_county fc ON cb.fipscounty = fc.fipscounty
JOIN population p ON fc.fipscounty = p.fipscounty
GROUP BY cb.cbsaname
ORDER BY total_population DESC
LIMIT 1;

SELECT cb.cbsaname, SUM(p.population) AS total_population
FROM CBSA cb
JOIN fips_county fc ON cb.fipscounty = fc.fipscounty
JOIN population p ON fc.fipscounty = p.fipscounty
GROUP BY cb.cbsaname
ORDER BY total_population ASC
LIMIT 1;

-- c. What is the largest (in terms of population) county which is not included in a CBSA?
-- Report the county name and population.
--Sevier TN 95523
SELECT fc.county, fc.state, p.population
FROM population p
JOIN fips_county fc ON p.fipscounty = fc.fipscounty
LEFT JOIN CBSA cb ON fc.fipscounty = cb.fipscounty
WHERE cb.fipscounty IS NULL
ORDER BY p.population DESC
LIMIT 1;

-- 6a. Find all rows in the prescription table where total_claims is at least 3000.
-- Report the drug_name and the total_claim_count.
--Oxycodone 4538, Levothyroxine sodium(x3) 3023,3138,3101,Furosemide 3083,Mirtazapine 3085,Hydrocodone-Acetaminophen 3376
--Gabapentin 3531, Lisinopril 3655

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT p.drug_name, p.total_claim_count, 
       CASE 
           WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
           ELSE 'not opioid'
       END AS drug_type
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
WHERE p.total_claim_count >= 3000;

-- c. Add another column to you answer from the previous part which gives the prescriber
-- first and last name associated with each row.

SELECT p.drug_name, p.total_claim_count, 
       CASE 
           WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
           ELSE 'not opioid'
       END AS drug_type,
       pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN prescriber pr ON p.npi = pr.npi
WHERE p.total_claim_count >= 3000;

-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
-- and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.
-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
-- where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


  SELECT pr.npi, p.drug_name
FROM prescriber pr
JOIN prescription p ON pr.npi = p.npi
JOIN drug d ON p.drug_name = d.drug_name
WHERE pr.specialty_description = 'Pain Management'
  AND pr.nppes_provider_city = 'NASHVILLE'
  AND d.opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
-- whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims
-- (total_claim_count).

SELECT pr.npi, p.drug_name, COALESCE(SUM(p.total_claim_count), 0) AS total_claim_count
FROM prescriber pr
JOIN prescription p ON pr.npi = p.npi
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY pr.npi, p.drug_name
ORDER BY pr.npi, p.drug_name; 