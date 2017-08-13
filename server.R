library(shiny)
library(shinydashboard)
library(dplyr)
library(DT)
library(shinyBS)
require(RPostgreSQL)



# Variables to set --------------------------------------------------------
email_text <- paste0("Dear FII Family - Our quality algorithm detected a potential error in your records. Can you please review your latest information? Thanks! - FII Team")

db <- "fii_data"
hostname = "localhost"
port_no = 5432
username = 'shannonlauricella'
password = pw
drv <- dbDriver("PostgreSQL")

metadata_table <- "fii_family"
anomaly_table <- "fii_anomalies_current"


# Input Data --------------------------------------------------------------
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = db,
                 host = hostname, port = port_no,
                 user = username, password = pw)
rm(pw) # removes the password

outliers <- dbReadTable(con, anomaly_table) %>% filter(Status=='FLAGGED')

flagged_families <- unique(outliers$FamilyID)

family_metadata <- dbReadTable(con, metadata_table) %>% 
  filter(FamilyId %in% flagged_families) %>%
  select(FamilyId, FamilyCode, GroupCode, ServiceLocation)

flagged_familycodes <- unique(family_metadata$FamilyCode)

flagged_locations <- c('All',sort(unique(as.character(family_metadata$ServiceLocation))))

outliers_w_metadata <- inner_join(outliers, family_metadata, by=c("FamilyID"="FamilyId"))


# Shiny Server ------------------------------------------------------------

server <- function(input, output, session) {
  
  # UI Input Selections + Filtering
  
  observe({
    if(input$location!='All'){
    updateSelectInput(session, "families", 
                    label = "Flagged Family Codes", 
                    choices = sort(unique((outliers_w_metadata %>% filter(ServiceLocation==input$location))$FamilyCode)))
    }
  })
  
  family_metadata_filt <- reactive({
    ifelse(input$location=='All', family_metadata, family_metadata %>% filter(ServiceLocation==input$location))
  })
  
  count <- reactive({
    ifelse(input$location=='All', nrow(family_metadata), 
           nrow(family_metadata %>% filter(ServiceLocation==input$location)))
  })
  
  flag_count <- reactive({
    ifelse(input$location=='All', nrow(outliers_w_metadata), 
           nrow(outliers_w_metadata %>% filter(ServiceLocation==input$location)))
  })
  
  
  selected_family <- reactive({
    outliers_w_metadata %>% filter(FamilyCode == input$families) %>% 
      select(FamilyCode, JournalDate, Measure, Value, Mean, STD, MonthsInFII)
  })
  
  
  # UI Messages and Actions
  observeEvent(input$clear, {
    output$textnew <- renderText({paste0("Do you want to clear flags?")})
  })
  
  observeEvent(input$send_email, {
    output$texttoemail <- renderText({email_text})
  })
  
  observe({
    if(input$copyText){
      clip <- pipe("pbcopy", "w")
      write.table(email_text, file=clip)
      close(clip)
    }
  })
  
  observe({
    input$clear
    if(input$yes_clear_flags== '1'){
      if(input$auditor != ""){
        output$curName <- renderUI({textInput("my_name", "Auditor name: ", input$new_name)})
      }
      if(input$confirmed){
        db_call <- paste0("INSERT INTO fii_anomalies SELECT \"FamilyID\",
                          \"MonthsInFII\",
                          \"Value\",
                          \"Mean\",
                          \"STD\",
                          \"JournalDate\",
                          \"Measure\",
                          'Cleared' \"Status\", 
                          '", input$auditor, "' \"AuthorID\",
                          now() \"InsertDate\" from fii_anomalies_current where \"FamilyID\" = ", 
                          (family_metadata %>% filter(FamilyCode==input$families))$FamilyId)
        dbGetQuery(con, db_call)
        toggleModal(session, "clearflagcheck", "close")
      }
      output$curName <- renderUI({textInput("my_name", "Current name: ", name)})
    }
  })
  
  
  # Output objects
  
  output$flagCount <- renderValueBox({
    valueBox(flag_count(), "Number of Flagged Points", icon=icon("flag"), color="red")
  })
  
  output$famCount <- renderValueBox({
    valueBox(count(), "Number of Flagged Families", icon=icon("flag"), color="red")
  })
  
  output$family_metadata <- renderDataTable({
    DT::datatable(family_metadata %>% filter(FamilyCode==input$families), rownames=FALSE, 
                  options=list(searching=FALSE, paging=FALSE, dom="t"))
  })

  
  output$family_data_errors <- renderDataTable({
    DT::datatable(selected_family() %>% arrange(Measure, JournalDate) %>% select(-FamilyCode, -MonthsInFII), rownames=FALSE, selection="multiple",
                  options=list(searching=FALSE, paging=FALSE, dom="t"))
  })


  
}