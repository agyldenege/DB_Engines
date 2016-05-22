#Get DB-Engines table data
require(rvest)

url <- "http://db-engines.com/en/ranking"

#Get the table data
html <- read_html(url) %>% html_nodes("table") %>% .[[4]]

#convert to a dataframe and use FILL
db_engines.clean <- html_table(html, fill=TRUE)[,c(4:5)]

#update names
names(db_engines.clean) <- c("database", "database_type")

#remove unnecessary columns created by FILL
db_engines.clean <- db_engines.clean[c(4:nrow(db_engines.clean)),]

#remove unnecessary text
db_engines.clean$database <- gsub(" Detailed vendor-provided information available", "", db_engines.clean$database)
