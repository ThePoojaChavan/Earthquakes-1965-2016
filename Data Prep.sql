/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Date]
      ,[Time]
      ,[Latitude]
      ,[Longitude]
      ,[Type]
      ,[Depth]
      ,[Depth Error]
      ,[Depth Seismic Stations]
      ,[Magnitude]
      ,[Magnitude Type]
      ,[Magnitude Error]
      ,[Magnitude Seismic Stations]
      ,[Azimuthal Gap]
      ,[Horizontal Distance]
      ,[Horizontal Error]
      ,[Root Mean Square]
      ,[ID]
      ,[Source]
      ,[Location Source]
      ,[Magnitude Source]
      ,[Status]
  FROM [Earthquakes].[dbo].[Original]

 /*
Dataset:https://www.kaggle.com/code/tastelesswine/earthquakes-from-1965-to-2016/data

Business Question - What are the factors associated with an earthquake:
location/region, 
date/time, 
Azimuthal gap, 
Root Mean Square, 
depth, 
depth error

We will clean/wrangle/explore the data in SQL Server flavor of SQL. The prepped data will be visualized in Tableau.

*/

--Step 1: Create a copy of the original dataset.
select  * into Copy
from Original

select * from Copy

-- The dataset has 21 columns and over 23000 rows.

--We do not have data dicationary, we will have alook at the various columns and try to understand what they tell us and also check if these in the right format?
exec sp_help Copy;

/*
--Many columns have date/time/numerical data and are stored as text, converting them to date/time/float/int as required

Date column needs to be changed from nvarchar to Date type
Time column needs to be changed from nvarchar to Time type
Latitude and Longitude columnd need to be changed from nvarchar to float type
Horizontal Distance, Horizontal Distance, Root Mean Square,Azimuthal gap and Depth Error columns need to be changed from nvarchar to float type

*/

--DATA WRANGLING: ALter the Date and Time columns--
alter table Copy
alter column Date date

alter table Copy
alter column Time time

alter table Copy
alter column Latitude float

alter table Copy
alter column Longitude	float

alter table Copy
alter column [Root Mean Square] float

alter table Copy
alter column [Azimuthal Gap] float

alter table Copy
alter column [Magnitude Error] float

alter table Copy
alter column [Magnitude Seismic Stations] int

alter table Copy
alter column [Horizontal Distance] float

alter table Copy
alter column [Horizontal Error] float

 alter table Copy
alter column [Depth Error] float

alter table Copy
alter column [Depth Seismic Stations] int


--DATA CLEANING

--Date column has dates of varying lengths, 3 rows have length of 24, while rest have lenth of 10
select distinct len(date) ,count(*) from Copy
group by len(date) ;

--lets see which 3 rows have date of length 24
select * from copy 
where len(Date) =24

-- Extract the left 10 characters and update/commit
select left(date,10) from copy 
where len(Date) =24

update Copy 
set Date = left(date,10)
where len(Date) =24

commit;

--Time column has same issue as the Date column, 3 rows have length of 24, while rest have lenth of 8
select distinct len(time) ,count(*) from Copy
group by len(time) ;

select time from copy 
where len(time) =24

--Extract the left 8 characters and update/commit (Note that the time column has accuracy of 100 nanoseconds hence format is hh:mmss[.nnnnnnn]
select left(date,10) from copy 
where len(Date) =24

--Checking for blanks (no recorded data) and nulls (absence of data) in the various columns.
-- We will replace numerical data with 0, 
select * from Copy

select [Depth Seismic Stations]
from copy
where
[Depth Seismic Stations] is null
or 
[Depth Seismic Stations] =' '

--or, we could also use coalesce in conjuction with NULLIF to check for nulls/blanks
select coalesce(nullif([Depth Seismic Stations],' '),0) from Copy;

--Update Nulls/blanks to 0 as [Depth Seismic Stations] are of int datatype
update Copy
set [Depth Seismic Stations]=	
case
	when [Depth Seismic Stations] is null then 0
	when [Depth Seismic Stations]=' ' then 0
	else [Depth Seismic Stations]
end;

select distinct [Depth Seismic Stations]
from copy

commit;

--Update Date column format to mm/dd/yyyy

select [Depth Error], len([Depth Error])
from copy
where len( [Depth Error])=0

select distinct [Magnitude Seismic Stations] from Copy;

update Copy
set [Magnitude Seismic Stations] =0 
where [Magnitude Seismic Stations] is null
--or

update Copy
set [Magnitude Seismic Stations] =coalesce([Magnitude Seismic Stations] ,0)

commit;

--Checking for duplicates
with dup as
(	select * , 
	ROW_NUMBER() over (partition by Date,Time, Latitude, Longitude order by ID) rownum
	from Copy)
select * from dup where rownum>1

--As part of prepping data and making it easy for EDA, we can extract year and month from the Date column)
select year(Date) from Copy;

select month(date) from Copy;

--Highest Earthquake magnitude is 9.1 and lowest is 5.5, which are both within the acceptable limits- No outliers as far as magnitude is concerned

select min(magnitude), max(magnitude) from Copy;

select * from Copy where Magnitude >9

--Checking for Outliers
select year(Date) from Copy
where year(Date) <1965
or year(Date) >2016

--We have two types of Status-Automatic and Reviewed
Select distinct Status from Copy;

--We have four types of Earthquakes subcat-Earthquake,Rock Burst, Explosion and Nuclear Explosion
Select distinct Type from Copy;

--We have various Location sources 
Select distinct [Location Source] from Copy
order by [Location Source];

--We have several sources from where we have obtained the Earthquake data
Select distinct Source from Copy;

--Adding new columns for Year,Month  for easier EDA and visualization
alter table Copy
add  Year int

alter table Copy
add  Month int

--inserting values in the newly created Year and Month columns
update Copy
set year= year(date)

update Copy
set Month= month(date)

commit;

select top 100*
from Copy

select distinct ID from COpy;

exec sp_help Copy;

--Exploratory Data Analysis
--Year 2011 saw the highest number of earthquakes
select year, count(*) as No_of_earthquakes
from Copy
group by year
order by  No_of_earthquakes desc

--March month saw the highest number of earthquakes, followed by August
select month, count(*) as No_of_earthquakes
from Copy
group by month
order by  No_of_earthquakes desc

-- around 3 in the night saw the most earthquakes
select left(time,8) as time_of_day, count(*) as No_of_earthquakes
from Copy
group by left(time,8)
order by  No_of_earthquakes desc

--Most of the earthquakes were  of the magnitude type MW (Movement W-phase) followed by MWC( Movemnt W-centroid), 3 are unknown
select [Magnitude Type], count(*) as No_of_earthquakes
from Copy
group by [Magnitude Type]
order by  No_of_earthquakes 

--We can also make a frequency distribution table aka histogram by creating magnitude bins, we will use CTE
with Hist as
(select magnitude,
	case
		When Magnitude < 6 then 'Below 6'
		When Magnitude >= 6 and Magnitude < 7 then 'Between 6 & 7'
		When Magnitude >= 7 and Magnitude < 8 then 'Between 7 & 8'
		When Magnitude >= 8 and Magnitude < 9 then 'Between 8 & 9'
		else 'More than 9'
	end as Mag_Bins	
from Copy
)

select	Mag_Bins,
		count(Mag_Bins) as Frequency
from Hist
group by Mag_Bins
order by Mag_Bins

--Most of the earthquakes were between magnitude 5.5 and 6
select Magnitude, count(*) as No_of_earthquakes
from Copy
group by Magnitude
order by  No_of_earthquakes desc

--Earthquakes accounted for 99% number of  explosions, followed by Nucleur explosions
select Type, count(*) as Num_of_explosions
from Copy
group by Type

--One thing that is missing from EDA is location of these earthquakes, which we will plot geographically (with Latitude and Longtitude fields) in Tableau