###########
##R Setup##
###########

#Libraries needed for the project
library(ggplot2)     #data visualization
library(tidyverse)   #code is in tidyverse format
library(countrycode) #used to match diverse country names and their iso_3
library(DescTools)   #assists with string manipulation

#Reading in our two datasets
#Reading in data for aid
aid <- read_csv("all_flow_classes.csv")

#Reading Polity IV data
polity <- read_csv("polity4v2017.csv")

#################
##Data Cleaning##
#################

#Taking the variables we want from our aid dataset
aid <- aid %>%
  group_by(recipients_iso3, year, recipients) %>%   #grouping by country code, year, country name
  count(crs_sector_name, flow,                      #count the number of times for sector investment, type of financing
        project_total_commitments)                  #amount of money committed

#Getting rid of regional recipients, we just want countries
aid$recipients <- ifelse(
  grepl("\\|", aid$recipients), #if a | is found (identifier for region), then
  NA, aid$recipients)           #make it NA, if not leave it as is
 
aid$recipients_iso3 <- ifelse(
  grepl("\\|", aid$recipients_iso3), 
  NA, aid$recipients_iso3)

#The polity dataset treats state failures as -77 and -88, but this will heavily skew our dataset. Since they don't really
#belong in any metric (because state failure almost means absence of effective government), we will denote them as NAs
polity$democ <- ifelse(polity$democ < -5, NA, polity$democ) #if anything lower than -5, make it NA, or else leave it alone
polity$xrreg <- ifelse(polity$xrreg < -5, NA, polity$xrreg)
polity$xrcomp <- ifelse(polity$xrcomp < -5, NA, polity$xrcomp)
polity$parcomp <- ifelse(polity$parcomp < -5, NA, polity$parcomp)

#The unique 3 letter identifier for polity (scode) is somehow very different from our aid iso_3 identifier, so let's change
#scode according to more commonly used iso_3
polity$scode <- countrycode::countrycode(polity$country, 'country.name', 'iso3c') #read countrycode readme for more details

#Polity data ranges from 1800 - present (where available), we are only concerned with 2000 - 2014
polity <- polity %>%
  filter(year >= 2000, year <= 2014) %>%
  select(scode, country, year, democ, xrreg, xrcomp, parcomp)

####################
##Merging datasets##
####################

combined <- left_join(aid, polity, by = c("recipients_iso3" = "scode", "year" = "year"))

#Erasing regional recipients again
combined$recipients <- ifelse(combined$recipients %like% "%regional", NA, combined$recipients) 

###################################
##Explaratory Data Analysis (EDA)##
###################################

#I love this part! Let's look at some of the distributions and derive insights from our visualizations

#Number of development projects per year
combined %>%
  group_by(year) %>%        #groups the calculations by year
  count(year) %>%           #county how many per year
  ggplot() +                #function to call ggplot
  geom_histogram(aes(x = year, y = n), stat = "identity") + #look at ggplot2 cheatsheet
  ylab("Count") +           #changing y axis label
  ggtitle("Number of Chinese-Funded Projects per Year") + #title of visualization
  xlab("Year")              #changing x axis label

#Top 15 sectors that China invests in by the amount of money
combined %>%
  group_by(crs_sector_name) %>%
  summarize(Sectors = sum(project_total_commitments, na.rm = TRUE)) %>% #create new column that sums the total amount
  arrange(desc(Sectors)) %>%     #arrange from highest to lowest
  slice(1:15) %>%                #take only top 15
  ggplot() + geom_histogram(aes(x = reorder(crs_sector_name, Sectors), y = Sectors/10^9), 
                            stat = "identity") +
  coord_flip() + xlab("Sectors/Industries") + ylab("Amount in Billions of USD") +
  ggtitle("Sectors/Industries China Funds")

#Total amount of aid by China per year
combined %>%
  group_by(year) %>%
  summarize(total = sum(project_total_commitments, na.rm = TRUE)) %>%
  ggplot() + geom_histogram(aes(x = year, y = total/10^9), stat = "identity") +
  ylab("Amount of $USD in Billions") + ggtitle("Total Aid by China per Year") +
  xlab("Year") + 
  geom_smooth(aes(x = year, y = total/10^9), method = "lm", se = FALSE) + #adding a linear regression line
  scale_x_continuous(breaks = c(2000,2002,2004,2006,2008,2010,2012,2014)) #scale the x axis by 2-year intervals

#Executive competition regulation rating (what does the law say about executive competition) 
combined %>%
  group_by(year) %>%
  count(xrreg) %>%
  drop_na() %>%
  ggplot() + geom_histogram(aes(x = year, y = n, fill = as.factor(xrreg)), stat = "identity", 
                            position = "fill") + 
  labs(fill = "Regulations for Competition") + #title for legend description
  ggtitle("Executive Regulation Competition around the World") +
  scale_fill_hue(labels = c("1 = Unregulated", "2 = Elite" , "3 = Regulated")) + #change legend explanation
  ylab("") + xlab("Year") + scale_x_continuous(breaks = c(2000,2002,2004,2006,2008,2010,2012,2014))

#Executive competition (what actually happens)
combined %>%
  group_by(year) %>%
  count(xrcomp) %>%
  ggplot() + geom_histogram(aes(x = year, y = n, fill = as.factor(xrcomp)), stat = "identity",
                            position = "fill") +
  labs(fill = "Executive Competition") +
  ggtitle("Executive Competition for Aid Recipients") +
  ylab("") +
  scale_fill_hue(labels = c("-5 = State Failure", "0 = Currently Transitioning", 
                            "1 = Selection", "2 = Dual/Transitional", "3 = Election")) +
  scale_x_continuous(breaks = c(2000,2002,2004,2006,2008,2010,2012,2014))

#Participation of citizens
combined %>%
  group_by(year) %>%
  count(parcomp) %>%
  drop_na() %>%
  ggplot() + geom_histogram(aes(x = year, y = n, fill = as.factor(parcomp)), position = "fill",
                            stat = "identity") +
  labs(fill = "Participation") +
  ggtitle("Participation of Citizens for Aid Recipients") +
  ylab("") +
  scale_fill_hue(labels = c("0 = Currently Transitioning", 
                            "1 = Repressed", "2 = Suppressed", "3 = Factional", "4 = Transitional", 
                            "5 = Competitive")) +
  xlab("Year") + scale_x_continuous(breaks = c(2000,2002,2004,2006,2008,2010,2012,2014))

######################
##Hypothesis Testing##
######################

country_list <- 
  as.data.frame(unique(combined$recipients_iso3)) #getting aggregate country list
colnames(country_list) <- "recipients_iso3"       #renaming column

sum(table(unique(agg_polity$scode))) #number of countries in our aggregate analysis

#Democracy rating for all aid recipients in 2000 and 2014
agg_polity <- polity %>%
  group_by(year, scode) %>%
  select(democ, xrreg, xrcomp, parcomp) %>%
  filter(year == 2000 | year == 2014) %>%
  inner_join(country_list, by = c("scode" = "recipients_iso3")) %>%
  select(year, scode, democ)

#Checking the distributions of both years for aggregate countries
ggplot(data = agg_polity) + geom_boxplot(aes(as.factor(x = year), y = democ)) +
  xlab("Year") + ylab("Democracy Rating (Lowest 0 Top 10)") +
  ggtitle("Checking Distribution for Democracy Rating (All Countries)")

#t-test for separate variances test
t.test(democ ~ year, data = agg_polity, alt = "less")

#Let's segment into the top 25th percentile to see whether receiving more aid also has a greater impact in changing 
#regime characteristics

#Calculating amount of money per recipient
amount_segment <- combined %>%
  group_by(recipients) %>%
  summarize(amount = sum(project_total_commitments, na.rm = TRUE)) %>%
  arrange(desc(amount))

#Top 25th percentile country list
top_25_names <- combined %>%
  group_by(recipients_iso3, recipients) %>%
  summarize(amount = sum(project_total_commitments, na.rm = TRUE)) %>%
  filter(amount > quantile(amount_segment$amount, prob = 0.75)) %>%   #using quantile to measure
  select(recipients, amount) %>%
  arrange(desc(amount))

#Formatting for top 25th percentile
top25_democ <- polity %>%
  group_by(year, scode) %>%
  select(democ, xrreg, xrcomp, parcomp) %>%
  filter(year == 2000 | year == 2014) %>%
  inner_join(top_25_names, by = c("scode" = "recipients_iso3")) %>%
  select(year, scode, democ)
top25_democ

#Checking the distributions of both years for top 25th percentile countries
ggplot(data = top25_democ) + geom_boxplot(aes(as.factor(x = year), y = democ)) +
  xlab("Year") + ylab("Democracy Rating (Lowest 0 Top 10)") +
  ggtitle("Checking Distribution for Democracy Rating (Top 25th Percentile)")

#T-test fpr top 25th percentile
t.test(democ ~ year, data = top25_democ, alternative = "less")

########################
##Visualization Poster##
########################

#Add group column for graphing lines, as well as logical vector if polity rating is lower in 2014
top_25$group <- as.factor(rep(1:33, each = 2))    #replicate 1 to 33, each one twice
logic_vector <- top_25 %>%
  select(recipients, year, democracy) %>%
  spread(key = year, value = democracy) %>%
  rename(Year2000 = "2000", Year2014 = "2014") %>%
  summarize(now = Year2014 > Year2000)            #based on if 2014 has a higher democracy rating than 2000

#Merging them together
top_25 <- left_join(top_25, logic_vector)
top_25$line_color <- ifelse(top_25$now == TRUE, "1", "2") #assigning numerical values to the logic vector

#Final graph
ggplot(data = top_25, aes(x = reorder(recipients, amount), y = democracy)) + 
  geom_point(aes(color = as.factor(year), size = amount)) + 
  geom_line(aes(group = group, color = line_color), linetype = "solid", size = 1.5) +
  coord_flip() + #flip the x and y axis
  labs(color = "", size = "", subtitle = "Ordered by Amount of Aid from China") +
  scale_color_manual(values = c("palegreen2","indianred2","gray","black"), #change the colors
                     labels = c("Improved", "Regressed", "2000", "2014")) +
  scale_size_continuous(breaks = c(10000000000,20000000000,30000000000), 
                        labels = c("$10 Billion", "$20 Billion", "$30 Billion")) +
  xlab("Countries (Ordered by Amount of Aid)") + ylab("Democracy Rating") +
  ggtitle("Has China's Aid Impacted Democracy?") +
  annotate("text", x = 33, y = 8.5, label = "USD$33.9 Billion", size = 3.5) + #add text into visualization
  annotate("text", x = 1, y = 8.5, label = "USD$1.9 Billion", size = 3.5) +
  annotate("text", x = 19, y = 8.5, label = "USD$6.5 Billion", size = 3.5) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "top",
    legend.justification = "center",
    legend.box.background = element_rect(),
    legend.box.margin = margin(6, 6, 6, 6),
    plot.title = element_text(hjust = 0.5),
    axis.title.y = element_blank(), 
    panel.grid.major.x = element_blank(),
    plot.subtitle = element_text(hjust = 0.5, face = "italic")
  )










