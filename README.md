# China's Investment Projects and their Impact on Regime Characteristics
Using financial and investment data from Aiddata (College of William and Mary) and regime characteristics data from the Polity IV series (Center for Systemic Peace) from 2000 - 2014, I investigated whether China has indeed had an impact on countries becoming more democratic or autocratic. The project involves data cleaning, wrangling, visualization, time-series analysis, and data analysis.

As published on: 
https://medium.com/@riorinaldietc/has-chinas-investments-succeeded-in-changing-country-governance-5c2a70fc9892

## Exploratory Data Analysis
The data coming from Aiddata and the Polity IV series packed a lot of information. After cleaning and wrangling the data to get it where I wanted to be, I explored much of what the data had to offer.

**Top 15 sectors that China was funding between 2000 - 2014**
![Top15_Sectors](https://user-images.githubusercontent.com/46828908/77263189-32a38100-6c6e-11ea-8b0a-d6fe11dd6f11.jpg)

**Total aid given by China (specific attention to 2009 where China took the mantle of global leadership after the 2008 Great Recession)**
![Total Aid by China](https://user-images.githubusercontent.com/46828908/77263382-8e6e0a00-6c6e-11ea-90e7-f9008aad21b2.jpg)

**Participation of citizens in the governmental process for those that received aid from China**
![Participation of Citizens - Mosaic](https://user-images.githubusercontent.com/46828908/77263414-b5c4d700-6c6e-11ea-8be8-60738f2d2d81.jpg)

## Hypothesis Testing
I was extremely interested to see whether there was a change in regimes with countries that had been receiving aid from China. Granted, I was limited in this analysis as I have yet to master time-series modeling and thus was relegated to using hypothesis testing. Employing a two sample t-test of democracy ratings for the top 25th percentile aid recipients, I got the following results:

```Welch Two Sample t-test

data:  democ by year
t = -0.7731, df = 63.513, p-value = 0.2212
alternative hypothesis: true difference in means is less than 0
95 percent confidence interval:
      -Inf 0.7024852
sample estimates:
mean in group 2000 mean in group 2014 
          3.575758           4.181818
```

Visualizing the data does tell a complicated story:
![Top 25 Democracy Rating Distribution](https://user-images.githubusercontent.com/46828908/77263922-b873fc00-6c6f-11ea-89ac-64937d33820e.jpg)

## Next Steps
Given that our data was limited from 2000 - 2014, we can see that the democracy ratings of aid recipients have actually increased. However, I do wonder whether this is because of a lag effect in regime changes. It will be interesting to revisit this project with data until 2020, where the election of populist and strongman leaders have most likely changed the regime landscape. 

**Below, a visualization I made showing the complicated picture that arises from China's aid and its impact on recipients**
![Top25_Democracy](https://user-images.githubusercontent.com/46828908/77264243-58ca2080-6c70-11ea-9023-6e9b6c1f0508.jpg)
