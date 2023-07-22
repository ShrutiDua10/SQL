CREATE DATABASE Data_Cleaning;
USE Data_Cleaning;

-- Cleaning Data on Nashville Housing using SQL. I have imported data using the table import wizard into the table nashville_housing
-- in the database Data_Cleaning

-- Raw Data 

SELECT * 
FROM nashville_housing;

 -- Standardizing the date format
 
 UPDATE nashville_housing SET SaleDate = IF(SaleDate='',NULL,SaleDate);
 
 SELECT SaleDate, CONVERT(SaleDate, DATE)
 FROM nashville_housing;
 
ALTER TABLE nashville_housing
ADD SaleDateNew DATE;

UPDATE nashville_housing
SET SaleDateNew = CONVERT(SaleDate, DATE);

-- Filling in the Property Address
-- After analysing the data we can see that the same Parcel IDs correspond to the same Property Addresses, however there are still
-- some properties with Parcel IDs but NULL Property Adresses. Hence, in the following section we are going to fill null address values
-- with the correct addresses using the Parcel IDs and Unique IDs to prevent duplicates

UPDATE nashville_housing SET PropertyAddress=IF(PropertyAddress='',NULL,PropertyAddress);

SELECT data_one.ParcelID, data_one.PropertyAddress, data_two.ParcelID, data_two.PropertyAddress, 
	   IFNULL(data_one.PropertyAddress,data_two.PropertyAddress)
FROM nashville_housing data_one
JOIN nashville_housing data_two
	ON data_one.ParcelID = data_two.ParcelID
	AND data_one.UniqueID <> data_two.UniqueID
WHERE data_one.PropertyAddress IS NULL;

UPDATE nashville_housing data_one
JOIN nashville_housing data_two
ON data_one.ParcelID = data_two.ParcelID
AND data_one.UniqueID <> data_two.UniqueID
SET data_one.PropertyAddress = IFNULL(data_one.PropertyAddress,data_two.PropertyAddress)
WHERE data_one.PropertyAddress IS NULL;

-- Splitting Address into individual columns (Street, City, State)
-- After analysing the data we can see that commas are the seperators between these three parts of the address, hence we will be using that

-- Property Address contains only street information and state so we split it into two columns

SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1) AS Street,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1 , LENGTH(PropertyAddress)) AS City
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD property_street VARCHAR(255);

UPDATE nashville_housing
SET property_street = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) -1);

ALTER TABLE nashville_housing
ADD property_city VARCHAR(255);

UPDATE nashville_housing
SET property_city = SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) +1, LENGTH(PropertyAddress));

SELECT property_street, property_city
FROM nashville_housing;

-- Owner address has all three street, city, and state hence we split into three columns

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS State,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2), ',', -1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD owner_street VARCHAR(255);

UPDATE nashville_housing
SET owner_street = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashville_housing
ADD owner_city VARCHAR(255);

UPDATE nashville_housing
SET owner_city = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2), ',', -1);

ALTER TABLE nashville_housing
ADD owner_state VARCHAR(255);

UPDATE nashville_housing
SET owner_state = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT owner_street, owner_city, owner_state
FROM nashville_housing;

-- Standardizing Y and N to Yes and No in "Sold as Vacant" field

UPDATE nashville_housing
SET SoldasVacant = 'Yes'
WHERE SoldasVacant = 'Y';

UPDATE nashville_housing
SET SoldasVacant = 'No'
WHERE SoldasVacant = 'N';

-- Removing Duplicates

DELETE data_one
FROM nashville_housing data_one, nashville_housing data_two
WHERE data_one.UniqueID <> data_two.UniqueID
  AND data_one.ParcelID = data_two.ParcelID
  AND data_one.PropertyAddress = data_two.PropertyAddress
  AND data_one.SalePrice = data_two.SalePrice
  AND data_one.SaleDate = data_two.SaleDate
  AND data_one.LegalReference = data_two.LegalReference;
  
-- Delete unnecessary columns

ALTER TABLE housing_data
DROP COLUMN OwnerAddress, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

-- Cleaned final data

SELECT * 
FROM nashville_housing;








  