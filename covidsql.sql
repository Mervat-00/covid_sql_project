--creating a database to hold the data in--
create database covid_data;
--exploring tables --
select top(5) * 
from covid_data..cases as c
left join covid_data..tests as t
on c.iso_code = t.iso_code
left join covid_data..vaccinations as v
on c.iso_code = t.iso_code
order by total_cases ;

--creating a CTE with data we will use repeatedly from cases table -- 
--creating an additional column  total deaths to total cases alising it as death_ratio

with main_cases_data as (
select iso_code ,location  , date , new_cases ,  total_cases , new_deaths ,total_deaths 
,  total_cases_per_million , total_deaths_per_million , round((total_deaths / total_cases)*100,2)as death_ratio
from covid_data..cases 
where location is not null)



--the highest 20 country in virus spread

select top (20) location , max(total_cases_per_million) as highestTotal
from main_cases_data 
group by location 
order by max(total_cases_per_million) desc ;



--showing likelihood of dying if you contract covid in these 20 countries --

with main_cases_data as (
select iso_code ,location  , date , new_cases ,  total_cases , new_deaths ,total_deaths 
,  total_cases_per_million , total_deaths_per_million , round((total_deaths / total_cases)*100,2)as death_ratio
from covid_data..cases 
where location is not null)

select top (20) location , max(total_cases_per_million) as highestTotal , avg( death_ratio) avg_death_ratio 
from main_cases_data 
group by location 
order by max(total_cases_per_million) desc ; 



-- select top months with above average virus spread for each country using CTEs --

with month_spread_avg as 
(select location , year(date) as year , month(date) as months , avg(total_cases_per_million) avg_per_month
from cases 
group by location, month(date) , year(date))

, country_spread_avg as
(select  location , avg(total_cases_per_million) as avg_total_country from cases group by location )


select country_spread_avg.location ,year, months ,  avg_per_month , avg_total_country
from month_spread_avg join country_spread_avg 
on country_spread_avg.location = month_spread_avg.location
where avg_per_month > avg_total_country
order by  avg_per_month desc;



-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as total_death_count
From cases
Where continent is not null 
Group by Location
order by total_death_count desc



-- Continent with Highest Death Count per Population

Select continent, MAX(cast(Total_deaths as int)) as total_death_count
From cases
Where continent is not null 
Group by continent
order by total_death_count desc


--The proportion of those who entered intensive care out of the proportion of those infected --
select location , avg(icu_patients / total_cases) as ratio
from cases
group by location 
order by ratio desc


--exploring vaccinations table--
select * from vaccinations


-- the propotion of people fully vaccinated for each country
select location , sum(people_fully_vaccinated / population) as vaccination_ratio 
from vaccinations
group by location
order by vaccination_ratio desc
 


--global numbers --

Select location ,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From cases
where continent is not null 
group by location
order by total_cases desc, total_deaths desc


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine using window functions

Select 
cases.Date ,
cases.location,
vaccinations.population, 
vaccinations.new_vaccinations
,SUM(convert(bigint , vaccinations.new_vaccinations)) OVER (Partition by cases.Location Order by cases.location, cases.Date) as rolling_people_vaccinated
From cases
Join vaccinations On cases.location = vaccinations.location and cases.date = vaccinations.date
order by 5 desc ;


--using temp tables to perform some calculations--

drop table if exists #percent_people_vaccinated

create table #percent_people_vaccinated
( Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vaccinated numeric)

insert into #percent_people_vaccinated
select cases.location , cases.date , cases.population , vaccinations.new_vaccinations ,
SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by cases.Location Order by cases.location, cases.Date) as rolling_people_vaccinated 
from cases join vaccinations 
on  cases.location = vaccinations.location
and cases.date = vaccinations.date 

select * , (rolling_people_vaccinated/Population)*100 as vaccinations_percent
from #percent_people_vaccinated
order by vaccinations_percent desc



-- Creating View to store data for later visualizations

create view percent_people_vaccinated as 
select cases.location , cases.date , cases.population , vaccinations.new_vaccinations ,
SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by cases.Location Order by cases.location, cases.Date) as rolling_people_vaccinated 
from cases join vaccinations 
on  cases.location = vaccinations.location
and cases.date = vaccinations.date 
where cases.continent is not null