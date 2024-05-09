select * from Portfolio.dbo.CovidDeaths
WHERE continent is not null
order by 3,4

select * from Portfolio.dbo.CovidVaccinations
order by 3,4

select location,date,population,total_cases,new_cases,total_deaths 
from Portfolio.dbo.CovidDeaths
order by 1,2


--Shows the total deaths in your country
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(18, 2), total_cases) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), total_cases) = 0 THEN NULL
        ELSE (TRY_CONVERT(DECIMAL(18, 2), total_deaths) * 100.0) / TRY_CONVERT(DECIMAL(18, 2), total_cases)
    END AS Death_Percentage
FROM 
    Portfolio.dbo.CovidDeaths
WHERE location like '%states%' and continent is not null

ORDER BY 
    location,
    date;

--Looking at total cases vs population
SELECT 
    location,
    date,
    total_cases,
    population,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(18, 2), total_cases) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), population) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), population) = 0 THEN NULL
        ELSE (TRY_CONVERT(DECIMAL(18, 2), total_cases) * 100.0) / TRY_CONVERT(DECIMAL(18, 2), population)
    END AS PercentPopulationInfected
FROM 
    Portfolio.dbo.CovidDeaths
WHERE location like '%states%' OR continent is not null
ORDER BY 
    location,
    date;

--Looking at countries with highest infection rate compared to population
SELECT 
    location,
    date,
    total_cases,
    population,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(18, 2), total_cases) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), population) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), population) = 0 THEN NULL
        ELSE (TRY_CONVERT(DECIMAL(18, 2), total_cases) * 100.0) / TRY_CONVERT(DECIMAL(18, 2), population)
    END AS PercentagePopulationinfected
FROM 
    Portfolio.dbo.CovidDeaths
	WHERE continent is not null
GROUP BY
    location,  -- Include all non-aggregated columns in the GROUP BY clause
    date, 
    total_cases,
    population
ORDER BY 
    PercentagePopulationinfected desc;

----Highest Death per population
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
WHERE continent is not null
Group by location
Order by TotalDeathCount desc;


--LETS BREAK THIS DOWN BY CONTINENT
Select continent,location, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
WHERE continent is not null
Group by continent,location
Order by TotalDeathCount desc;

--Showing continent with highest death per count population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio..CovidDeaths
WHERE continent is not null
Group by continent
Order by TotalDeathCount desc;



--Breaking global numbers
SELECT 
    date,
    SUM(TRY_CAST(new_cases AS INT)) AS total_new_cases,
    CASE 
        WHEN TRY_CONVERT(DECIMAL(18, 2), SUM(total_cases)) IS NULL OR TRY_CONVERT(DECIMAL(18, 2), SUM(total_cases)) = 0 THEN NULL
        ELSE (TRY_CONVERT(DECIMAL(18, 2), SUM(total_deaths)) * 100.0) / TRY_CONVERT(DECIMAL(18, 2), SUM(total_cases))
    END AS Death_Percentage
FROM 
    Portfolio.dbo.CovidDeaths
WHERE 
    continent IS NOT NULL
    AND ISNUMERIC(new_cases) = 1  -- Filter out non-numeric values
GROUP BY 
    date
ORDER BY 
    date;

--Select SUM(cast(new_cases as int)), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(cast(New_Cases as int))*100 as DeathPercentage
--From Portfolio..CovidDeaths
--Where location like '%states%'
--where continent is not null 
--Group By date
--order by 1,2


SELECT
    SUM(cast(new_cases as int)) AS TotalNewCases,
    SUM(cast(new_deaths as int)) AS TotalNewDeaths,
    CASE
        WHEN SUM(cast(new_cases as int)) = 0 THEN NULL
        ELSE SUM(cast(new_deaths as int)) / SUM(cast(New_Cases as int)) * 100
    END AS DeathPercentage
FROM
    Portfolio..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1, 2;


select new_cases from Portfolio..CovidDeaths order by new_cases desc






SELECT
    SUM(CAST(new_cases AS BIGINT)) AS TotalNewCases,
    SUM(CAST(new_deaths AS BIGINT)) AS TotalNewDeaths,
    CASE
        WHEN SUM(CAST(new_cases AS BIGINT)) = 0 THEN NULL
        ELSE CAST(SUM(CAST(new_deaths AS BIGINT)) AS FLOAT) / SUM(CAST(new_cases AS BIGINT)) * 100
    END AS DeathPercentage
FROM
    Portfolio..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

----LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT * FROM Portfolio..CovidDeaths DEA
JOIN Portfolio..CovidVaccinations VAC
ON DEA.LOCATION = VAC.LOCATION 
AND  DEA.DATE = VAC.DATE

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    Portfolio..CovidDeaths dea
JOIN
    Portfolio..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    dea.location,
    dea.date;



WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM
        Portfolio..CovidDeaths dea
    JOIN
        Portfolio..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)
SELECT
    *,
    (CAST(RollingPeopleVaccinated AS FLOAT) / Population) * 100 AS VaccinationPercentage
FROM
    PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


-- Create a temporary table to store the intermediate results
CREATE TABLE #PercentPopulationVaccinated (
    Continent VARCHAR(100),
    Location VARCHAR(100),
    Date DATE,
    Population INT,
    New_Vaccinations INT,
    RollingPeopleVaccinated INT
);

-- Create a temporary table to store the intermediate results
CREATE TABLE #PercentPopulationVaccinated (
    Continent VARCHAR(100),
    Location VARCHAR(100),
    Date DATE,
    Population INT,
    New_Vaccinations INT,
    RollingPeopleVaccinated INT
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(ISNULL(NULLIF(vac.new_vaccinations, ''), '0') AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    Portfolio..CovidDeaths dea
JOIN
    Portfolio..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date;

-- Query the temporary table with the division operation
SELECT
    *,
    CASE
        WHEN Population = 0 THEN NULL
        ELSE (CAST(RollingPeopleVaccinated AS FLOAT) / Population) * 100
    END AS VaccinationPercentage
FROM
    #PercentPopulationVaccinated;

-- Drop the temporary table after use
DROP TABLE #PercentPopulationVaccinated;


SELECT 
    *
FROM 
    Portfolio..CovidVaccinations
WHERE 
    ISNUMERIC(new_vaccinations) = 0;

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..CovidDeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 




