/****** Script for SelectTopNRows command from SSMS  ******/
SELECT * 
FROM PortfolioProject.dbo.CovidDeaths$ cd1q
WHERE cd1q.continent IS NOT NULL
ORDER BY 3,4



--Looking at total cases vs. total deaths
--shows the likelyhood dying if you contract covid in your country
SELECT cd.location, cd.date, cd.total_cases, cd.total_deaths, ([cd].[total_deaths]/cd.total_cases)*100 AS DeathPercentage 
FROM CovidDeaths$ cd
WHERE cd.location LIKE '%states%'
ORDER BY 1,2

--Looking at Total Cases vs. Population
SELECT cd.location, cd.date, cd.population, cd.total_cases, (cd.total_cases/cd.population)*100 AS DeathPercentage 
FROM CovidDeaths$ cd
WHERE cd.location LIKE '%states%'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population
SELECT cd.location, cd.population, MAX(cd.total_cases) AS HighestInfectionCount, MAX((cd.total_cases/cd.population))*100 AS PercentOfPopulationInfected 
FROM CovidDeaths$ cd
WHERE cd.continent IS NOT NULL
--cd.location LIKE '%states%'
GROUP BY cd.location, cd.population
ORDER BY PercentOfPopulationInfected DESC

--Let's break things down by continent
SELECT cd.location, MAX(CAST(cd.total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths$ cd
WHERE cd.continent IS NULL 
--cd.location LIKE '%states%'
GROUP BY cd.location
ORDER BY TotalDeathCount DESC


--Showing countries with the highest death count per population
--This query is show continents among countries, something that we need to cleanup. 
SELECT cd.location, MAX(CAST(cd.total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths$ cd
WHERE cd.continent IS NOT NULL 
--cd.location LIKE '%states%'
GROUP BY cd.location, cd.population
ORDER BY TotalDeathCount DESC

--Showing continents with the highest death count per population
SELECT cd.location, MAX(CAST(cd.total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths$ cd
WHERE cd.continent IS NULL 
--cd.location LIKE '%states%'
GROUP BY cd.location
ORDER BY TotalDeathCount DESC

--Global numbers
SELECT /*cd.date,*/ SUM(cd.new_cases) AS TotalCases, SUM(CAST(cd.new_deaths AS INT))AS TotalDeaths, SUM(CAST(cd.new_deaths as INT))/SUM(cd.new_cases)*100 AS DeathPercentage
FROM CovidDeaths$ cd
--WHERE cd.location LIKE '%states%'
WHERE cd.continent IS NOT NULL
--GROUP BY cd.date
ORDER BY 1,2

--Vaccination count --Use a CTE to figure it out
WITH PopVsVac (continent,location,date,population, new_vaccinations,RollingVaccinatedPeople)
AS
(SELECT 
cd.continent
,cd.location
,cd.date
,cd.population
,cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidVaccinations cv
JOIN CovidDeaths$ cd ON cv.location = cd.location
AND cv.date = cd.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *,(RollingVaccinatedPeople/population)*100
FROM PopVsVac

--Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccination NUMERIC,
RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
cd.continent
,cd.location
,cd.date
,cd.population
,cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidVaccinations cv
JOIN CovidDeaths$ cd ON cv.location = cd.location
AND cv.date = cd.date
WHERE cd.continent IS NOT NULL
--
SELECT*,(RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated ppv

-- **************** Go back and create  veiw for all the queries above.**********************
--Creating view to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated as
(SELECT 
cd.continent
,cd.location
,cd.date
,cd.population
,cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER(PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidVaccinations cv
JOIN CovidDeaths$ cd ON cv.location = cd.location
AND cv.date = cd.date
WHERE cd.continent IS NOT NULL
);
--query of the view
SELECT *
FROM PercentPopulationVaccinated ppv