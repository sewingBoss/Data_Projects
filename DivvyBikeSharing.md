DivvyBikeSharing
======

[Divvy](https://en.wikipedia.org/wiki/Divvy) is a bike sharing system in
Chicago recently acquired and owned by Lyft, Inc.  

*Management Decision Problem (MDP):* Let’s convert casual riders to members

*The Market research question (MRQ):* How do they each use Divvy?

We'll be using 12 months of ride data (MAY 2022 - APR 2023) published [here](https://divvybikes.com/system-data).  

  
-------
### Cleaning  
All cleaning was done in BigQuery SQL.

__NOTE__ Only more complex queries are displayed here. For the rest, please see [here](link).  

  
[Someone said](https://medium.com/@iainselliott/google-data-analytics-capstone-project-cyclistic-case-study-8baed2f5a286) that classic and docked bikes are the same so I pretended that my hypothetical boss confirmed this and converted all to classic.  

[The same person](https://github.com/iainelli/Capstone-Project-Cyclistic-Case-Study/blob/main/data_cleaning_analysis.sql) had a list of stations that were service stations for the bikes and not public. I checked the rows with these and the amount of missing data in those rows convinced me that this was true; again, in real life I would confirm with my boss, which I will pretend I did for now.  

Ride length was computed from the timestamps  

Rides start from 1 minute, and anything longer than 24 is considered stolen or missing
