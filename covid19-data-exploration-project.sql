Link to Dataset: https://ourworldindata.org/covid-deaths

Data Exploration Project: COVID-19 Deaths and Vaccinations up to July 2022

-- Examine the CovidDeaths dataset

SELECT *
FROM [covid19-portfolio-project]..[CovidDeaths]
ORDER BY location, date

-- Select Data that I'm going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [covid19-portfolio-project]..[CovidDeaths]
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_percentage
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE location = 'Vietnam'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 as cases_per_population
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE location = 'Vietnam'
ORDER BY 1,2

-- Looking at coutnry with highest Infection Rate compared to Population

SELECT location, 
	population, 
	MAX(total_cases) as highest_infection_count,  
	MAX((total_cases/population))*100 as percentage_population_infected
FROM [covid19-portfolio-project]..[CovidDeaths]
GROUP BY location, population
ORDER BY percentage_population_infected DESC

--Shows the countries with the Highest Death count per population
-- We need to cast total_deaths column to change it data type from nvarchar to bigint

SELECT location, 
	population, 
	MAX(CAST(total_deaths as bigint)) as total_death_count
FROM [covid19-portfolio-project]..[CovidDeaths]
GROUP BY location, population
ORDER BY total_death_count DESC

-- We will have to add the WHERE continent IS NOT NULL to filter out 'location' that are not countries
-- WHERE continent IS NOT NULL

SELECT location, 
	population, 
	MAX(CAST(total_deaths as bigint)) as total_death_count
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC

-- View data when they are grouped by continent
-- To exclude the Income groups, I have to add condition where it will return some specific results

SELECT location, 
	MAX(CAST(total_deaths as bigint)) as total_death_count
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NULL 
AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania', 'European Union')
GROUP BY location
ORDER BY total_death_count DESC

-- This is the alternative way to filter out the Income groups

SELECT location, 
	MAX(CAST(total_deaths as bigint)) as total_death_count
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NULL 
AND location NOT LIKE ('%income')
GROUP BY location
ORDER BY total_death_count DESC

-- Shows the continent with the highest death count per population

SELECT location, 
	MAX(CAST(total_deaths as bigint)) as total_death_count
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NULL 
AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC

-- GLOBAL NUMBERS
-- Find out the death percentage for each day in the World

SELECT date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths as bigint)) AS total_deaths,
	SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 AS death_percentage
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1 DESC,2

-- Total Cases vs Total Deaths in the World

SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths as bigint)) AS total_deaths,
	SUM(CAST(new_deaths as bigint))/SUM(new_cases)*100 AS death_percentage
FROM [covid19-portfolio-project]..[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Examine the CovidVaccinations dataset

SELECT *
FROM [covid19-portfolio-project]..[CovidVaccinations]
ORDER BY location, date

-- Joining the tables together

SELECT *
FROM [covid19-portfolio-project]..[CovidDeaths] AS dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] AS vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Looking at Total Population vs Vaccinations
-- Total amount of people in the World that have been vaccinated

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations
FROM [covid19-portfolio-project]..[CovidDeaths] AS dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--GROUP BY dea.location, dea.population
ORDER BY 1, 2, 3

-- Add up New_vaccinations through out the date for each countries
-- By input the SUM with PARTITION BY clause, we make the new vaccinations add up whenever the data get new records

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM [covid19-portfolio-project]..[CovidDeaths] dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Use CTE

With PopvsVac(continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS 
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM [covid19-portfolio-project]..[CovidDeaths] dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,
	(rolling_people_vaccinated/population)
FROM PopvsVac

-- Create Temporary Table

DROP TABLE IF EXISTS #Percent_population_vaccinated
CREATE TABLE #Percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated bigint
)

INSERT INTO #Percent_population_vaccinated
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM [covid19-portfolio-project]..[CovidDeaths] dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,
	(rolling_people_vaccinated/population)*100
FROM #Percent_population_vaccinated

-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM [covid19-portfolio-project]..[CovidDeaths] dea
JOIN [covid19-portfolio-project]..[CovidVaccinations] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
