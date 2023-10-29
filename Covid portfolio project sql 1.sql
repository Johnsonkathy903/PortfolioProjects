select * 
from portfolioproject..coviddeaths
order by 3,4

--select * 
--from portfolioproject..Vaccinations
--order by 3,4

--select data 

select location,date,total_cases,new_cases,total_deaths,population
from portfolioproject..coviddeaths
order by 1,2

--Looking at total cases VS total deaths
--shows the likelihood of dying if you contract covid in your country

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 deathpercentage
from portfolioproject..coviddeaths
where location like '%states%'
order by 1,2

SELECT
    location,
    date,
    CAST(total_cases AS float) AS total_cases,
    CAST(total_deaths AS float) AS total_deaths,
    (total_deaths / total_cases) * 100 AS deathpercentage
FROM
    portfolioproject..coviddeaths

	SELECT
    location,
    date,
    TRY_CAST(total_cases AS float) AS total_cases,
    TRY_CAST(total_deaths AS float) AS total_deaths,
    (TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)) * 100 AS deathpercentage
FROM
    portfolioproject..coviddeaths
WHERE
    location LIKE '%states'
    AND TRY_CAST(total_cases AS float) IS NOT NULL
    AND TRY_CAST(total_deaths AS float) IS NOT NULL
ORDER BY
    location,
    date;



	SELECT
    location,
    date,
    TRY_CAST(total_cases AS float) AS total_cases,
    TRY_CAST(total_deaths AS float) AS total_deaths,
    (TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)) * 100 AS deathpercentage
FROM
    portfolioproject..coviddeaths


-- Looking at Total Cases vs Population

SELECT
    location,
    date,
    TRY_CAST(total_cases AS float) AS total_cases,
    TRY_CAST(population AS float) AS population,
    (TRY_CAST(population AS float) / TRY_CAST(total_cases AS float)) * 100 AS deathpercentage
FROM
    portfolioproject..coviddeaths
WHERE location LIKE '%states'
    AND TRY_CAST(total_cases AS float) IS NOT NULL
    AND TRY_CAST(population AS float) IS NOT NULL
ORDER BY
    location,
    date;

--Looking at countries with highest infection rate compared to population

SELECT
    location,
    population,
	Max(total_cases) as HighestinfectionCount, MAX((total_cases/population))*100 as perctentpopulationinfected
FROM portfolioproject..coviddeaths
--where location like '%states%'
Where continent is not null
group by location,population
order by perctentpopulationinfected desc

-- Showing Countries with the highest death count per population

SELECT location,
	Max(cast(total_deaths as int)) totaldeathcount
FROM portfolioproject..coviddeaths
--where location like '%states%'
Where continent is not null
group by location
order by totaldeathcount desc

-- Break down by continent
-- Showing the cotinents with the highest death count per population

SELECT continent,
	Max(cast(total_deaths as int)) totaldeathcount
FROM portfolioproject..coviddeaths
--where location like '%states%'
Where continent is not null
group by continent
order by totaldeathcount desc

--Global Numbers

SELECT date,sum(new_cases), sum(cast(new_deaths as int)), sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM portfolioproject..coviddeaths
--where location like '%states%'
Where continent is not null
group by date
order by 1,2

SELECT
    SUM(new_cases) as total_cases,
    SUM(CAST(new_deaths AS int)) as total_deaths,
    CASE
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS int)) * 100.0) / SUM(new_cases)
    END AS DeathPercentage
FROM
    portfolioproject..coviddeaths
--where location like '%states%'
WHERE
    continent IS NOT NULL
--GROUP BY date
ORDER BY
    1,2;

--Looking at total population vs vaccinations

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date)
from portfolioproject..coviddeaths dea
join portfolioproject..Vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
order by 2,3

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
FROM
    portfolioproject..coviddeaths dea
JOIN
    portfolioproject..Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY 2,3


--use cte

with popvsvac (continet, location,date,population,new_vaccinations,rollingpeoplevaccinated)
as
(
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
FROM
    portfolioproject..coviddeaths dea
JOIN
    portfolioproject..Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY 2,3
)
select*, (rollingpeoplevaccinated/population)*100
from popvsvac


--temp table

Drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

Insert into #percentpopulationvaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
FROM
    portfolioproject..coviddeaths dea
JOIN
    portfolioproject..Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY 2,3

select*, (rollingpeoplevaccinated/population)*100
from #percentpopulationvaccinated


--creating veiw to store data for later visualization

create view percentpopulationvaccinated as
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS bigint)) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rollingpeoplevaccinated
FROM
    portfolioproject..coviddeaths dea
JOIN
    portfolioproject..Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
--ORDER BY 2,3

select*
from percentpopulationvaccinated
