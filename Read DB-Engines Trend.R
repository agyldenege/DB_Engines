#Get trend data for DB-Engines
#install.packages("reshape")
require('stringr')
require('rvest')
require(RJSONIO)
require(jsonlite)
require(reshape)
require(sqldf)

#URL we want to scrape
url = "http://db-engines.com/en/ranking_trend"

html <- read_html(url) %>% html_nodes('script') %>% .[5] #Get the javascript data

#Get Start Date
start <- regexpr('dbe_startdate = Date.UTC', html)[1] + 24 + 1
end <- regexpr(';', html)[1] -1 -1
start_date <- substr(html, start, end)

json.start = regexpr('var dbe_data', html)
json.end = regexpr('var dbe_title', html)
json.text = substr(html, json.start, json.end)

json.text = gsub('var dbe_data = \\[\n', '[', json.text)
json.text = gsub('\\}\\]\nv', '}]', json.text)

json.text = gsub(', visible:false', '', json.text)
json.text = gsub('\n', '', json.text)
json.text = gsub('null', '0.00001', json.text) #replace nulls with 0.00001

json.text = gsub('null', '0.00001', json.text) #replace nulls with 0.00001
json.text = gsub('name:', '"name":', json.text) 
json.text = gsub('data:', '"data":', json.text) 

json.json = fromJSON(json.text)


json.final <- vector("list", length(json.json[[1]])) #Create empty list


#populate list with clean data
for (i in 1:length(json.json[[1]])) {
  json.final[[i]] <- json.json[[1]][i]
  names(json.final[[i]]) <- json.json[[2]][i]
}



#convert to dataframe
db_trends <- (as.data.frame(json.final))

#create a string of dates
start_date <- as.Date("2012-11-01")
date_range <- seq.Date(start_date, Sys.Date(), "month")
db_trends$rank_date <- date_range #Assign date range

#reshape the data
db_trends.normalized <- melt(db_trends, id="rank_date") #reshape
names(db_trends.normalized) <- c("rank_date", "database", "rank") #proper names
db_trends.normalized$rank[db_trends.normalized$rank == 0.00001] <- NA #remove 0.00001 dummy value
db_trends.normalized <- sqldf("select rank_date, replace(database, '.', ' ') database, cast(rank as numeric) rank from [db_trends.normalized]")
write.csv(db_trends.normalized, "db_trends.csv", row.names = FALSE)
