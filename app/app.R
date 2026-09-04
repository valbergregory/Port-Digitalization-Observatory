# Brazilian Port Digital Transformation Observatory — esqueleto do Shiny.
# Consome apenas artefatos já auditados. Hoje: painel mínimo de comércio +
# registro preliminar de intervenções. Módulos futuros: eficiência, event
# study, qualidade de dados, exportação de evidências.

library(shiny)
library(data.table)

raiz <- normalizePath(file.path(dirname(getwd()), basename(getwd())), winslash = "/")
painel_path <- file.path("..", "data", "interim", "painel_urf_mes_maritimo_2024Q1.csv")
if (!file.exists(painel_path)) painel_path <- file.path("data", "interim", "painel_urf_mes_maritimo_2024Q1.csv")

ui <- fluidPage(
  titlePanel("Brazilian Port Digital Transformation Observatory — protótipo"),
  sidebarLayout(
    sidebarPanel(
      selectInput("fluxo", "Fluxo", c("export", "import")),
      uiOutput("urf_ui"),
      helpText("Amostra 2024T1 (Comex Stat, via marítima). O módulo operacional",
               "(T1–TE por porto) será ligado quando os microdados ANTAQ voltarem.")
    ),
    mainPanel(
      plotOutput("serie"),
      tableOutput("tabela")
    )
  )
)

server <- function(input, output, session) {
  dados <- reactive({
    validate(need(file.exists(painel_path), "Painel mínimo ainda não materializado."))
    fread(painel_path, colClasses = list(character = "co_urf"))
  })
  output$urf_ui <- renderUI({
    selectInput("urf", "URF (porto)", sort(unique(dados()$urf_nome)))
  })
  base <- reactive({
    d <- dados()[fluxo == input$fluxo & urf_nome == input$urf]
    d[order(ano, mes)]
  })
  output$serie <- renderPlot({
    d <- base()
    plot(d$mes, d$vl_fob_usd / 1e6, type = "b", xlab = "Mês (2024)",
         ylab = "FOB (US$ milhões)", main = input$urf)
  })
  output$tabela <- renderTable(base())
}

shinyApp(ui, server)
