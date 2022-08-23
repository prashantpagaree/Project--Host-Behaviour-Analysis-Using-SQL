
Use Project;

--vancouver
select * from [dbo].[df_vancouver_availability]
select * from[dbo].[host_vancouver_df]
Select * from [dbo].[listing_vancouver_df]
Select * from [dbo].[review_vancouver_df]

--Vancouver
Select * from [dbo].[host_vancouver_df]
Select * from [dbo].[listing_vancouver_df]
Select * from [dbo].[review_vancouver_df]
Select * from [dbo].[df_vancouver_availability]

/*a. Analyze different metrics to draw the distinction between Super Host and Other Hosts:
To achieve this, you can use the following metrics and explore a few yourself as well. 
Acceptance rate, response rate, instant booking, profile picture, identity verified,
review review scores, average no of bookings per month, etc. */ 

--Acceptance rate, response rate
Select Avg(host_response_rate) As host_response_rate,Avg(host_acceptance_rate) as host_acceptance_rate,
host_is_superhost from [dbo].[host_vancouver_df] 
where  host_response_rate is not null or host_acceptance_rate is not null  group by host_is_superhost;


--profile picture
select host_is_superhost,sum(true) as Host_have_profile_pic,sum(false)as Host_dont_have_profile_pic from(
select host_is_superhost,[TRUE],[FALSE] from [dbo].[host_vancouver_df]
pivot (count(host_id) for
host_has_profile_pic in ([TRUE],[FALSE]))a)a group by host_is_superhost

--identity verified
select host_is_superhost,sum(true) as Verified,sum(false)as Not_verified from(
select host_is_superhost,[TRUE],[FALSE] from [dbo].[host_vancouver_df]
pivot (count(host_id) for
host_Identity_verified in ([TRUE],[FALSE]))a)a group by host_is_superhost

--instant booking

Select B.Host_is_superhost,A.instant_bookable,Count(A.HOST_ID) AS count 
From listing_vancouver_df A Inner Join host_vancouver_df B 
ON A.HOST_ID = B.HOST_ID Group by Host_is_superhost,instant_bookable 

--review review scores

Select B.Host_is_superhost,avg(A.review_scores_value) as review_scores_value  
From listing_vancouver_df A Inner Join host_vancouver_df B 
ON A.HOST_ID = B.HOST_ID Group by Host_is_superhost

--average no of bookings per month

Select *,Avg(Total_Bookings)Over(Partition by Month,host_is_superhost Order by Month) as Avg_bookings 
from(
Select month(a.date) as Month, Count(B.id) as Total_Bookings,C.host_is_superhost
from review_vancouver_df A Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID where host_is_superhost is not null
group by month(date),Year(Date),C.host_is_superhost )c 


/*Select Month(A.Date) Month,Year(A.Date) As Year ,C.host_is_superhost, Count(A.ID) from review_vancouver_df A 
Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID where Month(A.date) = 1 AND C.host_is_superhost='FALSE'
Group by Month(A.Date),Year(A.Date),C.host_is_superhost;*/

/*b. Using the above analysis, identify top 3 crucial metrics one needs to maintain 
to become a Super Host and also, find their average values.*/




/*c. Analyze how does the comments of reviewers vary for listings of Super Hosts vs Other 
Hosts(Extract words from the comments provided by the reviewers)*/

---Other Host - 137810
---Superhost - 138324
Select Sum(Total_Comments) from (
Select A.comments,Count(B.Host_ID) As Total_comments
from review_vancouver_df A Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID 
where C.Host_is_superhost = 'TRUE' and A.comments  like '%Beautiful%' or A.comments  like '%Fantastic%'
or A.comments  like '%100%%' or A.comments  like '%10/10%'
or A.comments  like '%11/10%' or A.comments  like '%12/10%'
or A.comments  like '%5 star%' or A.comments  like '%5 of 5 stars%'
or A.comments  like '%Great%' or A.comments  like '%Clean%'
or A.comments  like '%amazing%' or A.comments  like '%Wonderful%'
or A.comments  like '%5star%' or A.comments  like '%best%'
or A.comments  like '%Definitely%' or A.comments  like '%excellent%'
or A.comments  like '%Awesome%' or A.comments  like '%excellent%'
or A.comments  like '%Decent%'or A.comments  like '%Well%'
or A.comments  like '%quiet%' or A.comments  like '%love%'
group by A.comments) c



Select A.comments,Count(B.Host_ID) As Total_comments
from review_vancouver_df A Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID 
where C.Host_is_superhost = 'TRUE' group by A.comments

Select A.comments,Count(B.Host_ID) As Total_comments
from review_vancouver_df A Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID 
where C.Host_is_superhost = 'FALSE' group by A.comments

/*d. Analyze do Super Hosts tend to have large property types as compared to Other Hosts*/


Select Count(A.Host_ID),A.Property_type
From listing_vancouver_df A Inner Join host_vancouver_df B 
ON A.HOST_ID = B.HOST_ID where B.Host_is_superhost = 'False'  and property_type  like '%ENTIRE%'
group by A.Property_type

Select Count(A.Host_ID),A.Property_type
From listing_vancouver_df A Inner Join host_vancouver_df B 
ON A.HOST_ID = B.HOST_ID where B.Host_is_superhost = 'TRUE' and property_type  like '%ENTIRE%'
group by A.Property_type

/*e. Analyze the average price and availability of the listings for the upcoming year 
between Super Hosts and Other Hosts*/

--AVG_PRICE
Alter procedure p1 @superhost nvarchar(10) as begin 
Select * from (
Select A.listing_id,AVG(A.Price) AS AVG,YEAR(date) AS YEAR
from df_vancouver_availability A Inner Join listing_vancouver_df B ON A.listing_id = B.id
Inner join host_vancouver_df C ON B.Host_ID = C.HOST_ID WHERE C.host_is_superhost = @superhost
GROUP BY A.listing_id,YEAR(date))c
PIVOT(AVG(AVG) for Year IN ([2022],[2023])) as PVT2
end;

exec p1 'TRUE';

--AVAILABILITY

Select A.listing_id,count(A.available) as ava,YEAR(A.date) AS YEAR into #mmm
from df_vancouver_availability as A  Inner Join listing_vancouver_df as  B ON A.listing_id = B.id
Inner join host_vancouver_df as  C ON B.Host_ID = C.HOST_ID WHERE C.host_is_superhost = 'True' and A.available='True'
GROUP BY A.listing_id,YEAR(A.date)
Select A.listing_id,count(A.available) as total,YEAR(A.date) AS YEAR into #nnn
from df_vancouver_availability as A Inner Join listing_vancouver_df as  B ON A.listing_id = B.id
Inner join host_vancouver_df as  C ON B.Host_ID = C.HOST_ID WHERE C.host_is_superhost = 'True'
GROUP BY A.listing_id,YEAR(A.date)
select top 10* from #mmm order by listing_id,year
select  top 10* from #nnn order by listing_id,year
select A.listing_id , (A.ava)*100/B.total as per,A.year from #mmm as A inner join #nnn as B on
A.listing_id=B.listing_id where A.year=B.year
order by A.listing_id, A.year



/*f. Analyze if there is some difference in above mentioned trends between Local Hosts
or Hosts residing in other locations */
--LocalHost

Select A.host_id Into #aaa
FROM [dbo].[listing_vancouver_df] A INNER JOIN [dbo].[host_vancouver_df] B ON A.host_id = B.host_id 
WHERE B.host_neighbourhood = A.neighbourhood_cleansed

--Residing in other area
Select A.host_id into #bbb
FROM [dbo].[listing_vancouver_df] A INNER JOIN [dbo].[host_vancouver_df] B ON A.host_id = B.host_id 
WHERE B.host_neighbourhood != A.neighbourhood_cleansed

/*g. Analyze the above trends for the two cities for which data has been provided 
and provide insights on comparison */



Select A.Host_id, Avg(host_response_rate) As host_response_rate,Avg(host_acceptance_rate) 
as host_acceptance_rate from [dbo].[host_vancouver_df] B Inner Join #bbb A ON A.host_id = B.host_id
where  host_response_rate is not null or host_acceptance_rate is not null GROUP BY A.host_id;

















