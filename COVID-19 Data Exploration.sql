/*
COVID 19 Data Exploration
*/

-- Raw Data (https://ourworldindata.org/covid-deaths)

SELECT * 
FROM CovidProject.coviddeaths;

SELECT * 
FROM CovidProject.covidvaccinations;

-- COVID Deaths table

SELECT * 
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Selecting data that will be used 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total Cases vs Total Deaths
-- This segment shows the likelihood of dying if a person contracts COVID in UAE. 
-- This likelihood is calculated by the DeathPercentage which is (total_deaths/total_cases)*100

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidProject.coviddeaths
WHERE location like '%Arab Emirates' AND continent IS NOT NULL
ORDER BY location, date;

-- Total Cases vs Population
-- This segment shows what percentage of the population is infected with COVID.

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectedPercentage
FROM CovidProject.coviddeaths
ORDER BY location, date;

-- Countries with Highest Infection rate compared to Population

SELECT location, population, MAX(total_cases) as MaxCases, MAX((total_cases/population)*100) AS HighestInfectedPercentage
FROM CovidProject.coviddeaths
GROUP BY location, population
ORDER BY HighestInfectedPercentage DESC;

-- Countries with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS DeathCount
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with Highest Infection rate compared to Population

SELECT continent, SUM(population) as population, MAX(total_cases) as MaxCases, MAX((total_cases/population)*100) AS HighestInfectedPercentage
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestInfectedPercentage DESC;

-- Contintents with the Highest Death Count

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS DeathCount
FROM CovidProject.coviddeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY DeathCount DESC;

-- GLOBAL NUMBERS

-- Grouped by Date
-- This section shows the global numbers grouped by date. It shows the total cases, total deaths, and
-- the death percentage on each day starting from 

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- Complete total
-- This section shows the total cases, total deaths, and the final death percentage globally
-- that were calculated from 

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidProject.coviddeaths
WHERE continent IS NOT NULL;

-- COVID Vaccinations table 

SELECT * 
FROM CovidProject.covidvaccinations
ORDER BY location, date;

-- Total Population vs Vaccinations
-- This section finds the total number of vaccines in a location by adding number of new vaccinations per day to the total. It shows the progress
-- of a country everyday in terms of vaccinations

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by death.Location Order by death.location, death.Date) as vac_total_perday
FROM CovidProject.coviddeaths AS death
JOIN CovidProject.covidvaccinations AS vac
	ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;

-- This section uses the above to show the progress of a country everyday in terms of percentage of the population that recieved vaccinations

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
       (SUM(CAST(vac.new_vaccinations AS UNSIGNED)) / death.population) * 100 AS vac_perc_perday
FROM CovidProject.coviddeaths AS death
JOIN CovidProject.covidvaccinations AS vac
    ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL
GROUP BY death.continent, death.location, death.date, death.population, vac.new_vaccinations
ORDER BY death.location, death.date;

-- Understanding the above two sections using CTE and Temp Tables

WITH CTE_vac (continent, location, date, population, new_vaccinations, vac_total_perday)
AS (SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by death.Location Order by death.location, death.Date) as vac_total_perday
	FROM CovidProject.coviddeaths AS death
	JOIN CovidProject.covidvaccinations AS vac
		ON death.location = vac.location
		AND death.date = vac.date
	WHERE death.continent IS NOT NULL
	ORDER BY 2,3
	)
SELECT *, (vac_total_perday/population) * 100 as vac_perc_perday
FROM CTE_vac;

-- Temp table

DROP TABLE IF EXISTS vaccinated_population;
CREATE TABLE vaccinated_population
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
vac_total_perday numeric
);

INSERT INTO vaccinated_population
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by death.Location Order by death.location, death.Date) as vac_total_perday
FROM CovidProject.coviddeaths AS death
JOIN CovidProject.covidvaccinations AS vac
	ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;

SELECT *, (vac_total_perday/population) * 100 as vac_perc_perday
FROM vaccinated_population;

-- Creating a View for further visualization

CREATE VIEW vaccinated_population_perc AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by death.Location Order by death.location, death.Date) as vac_total_perday
FROM CovidProject.coviddeaths AS death
JOIN CovidProject.covidvaccinations AS vac
	ON death.location = vac.location
    AND death.date = vac.date
WHERE death.continent IS NOT NULL;

SELECT *
FROM vaccinated_population_perc;


























