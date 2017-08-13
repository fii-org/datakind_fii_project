library(shinydashboard)

dashboardPage(
  dashboardHeader(title='FII Audit Dashboard'),
  dashboardSidebar(
    sidebarMenu(id = "menu_tabs",
                menuItem("Error Overview", tabName="overview"),
                menuItem("Error Breakdown", tabName="breakdown"),
                uiOutput("familyFilter"),
                selectInput("families", "Flagged Family IDs", as.list(sort(flagged_familycodes))),
                selectInput("location", "Service Locations", as.list(flagged_locations))
                )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName="overview" , 
              fluidRow(
                valueBoxOutput("flagCount"),
                valueBoxOutput("famCount")
              )
            ),
      tabItem(tabName="breakdown",
              fluidRow(
              box(
                title = "Family Information", status = "primary", solidHeader = TRUE,
                collapsible = FALSE,
                div(style = 'overflow-x: scroll',
                DT::dataTableOutput("family_metadata"),
                tags$style(type="text/css", '#family_metadata tfoot {display:none;}'))
              ),
              box(
                width = 3,
                title = "Take action", status="primary", solidHeader = TRUE,
                actionButton("send_email", "Generate e-mail for family"),
                br(),
                br(),
                actionButton("clear", "Clear flags"),
                bsModal("clearflagcheck", "Clear flags", "clear", size = "small",
                        textOutput("textnew"),
                        radioButtons("yes_clear_flags", "", choices = list("Yes" = 1, "No" = 2),selected = 2),
                        conditionalPanel(condition = "input.yes_clear_flags == '1'",textInput("auditor", "Enter Auditor Name:", "")),
                        actionButton("confirmed", "Finished")
                        
                ),
                bsModal("emailtext", "Email text", "send_email", size = "small",
                        textOutput("texttoemail"),
                        actionButton("copyText", "Copy text")
              )),
              fluidRow(
              box(
                title = "Flagged Measures", status = "primary", solidHeader=TRUE,
                collapsible=FALSE,
                DT::dataTableOutput("family_data_errors")
              )))
    )

  )
))
