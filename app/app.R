# Brazilian Port Digital Transformation Observatory — Shiny.
# Quatro paineis (escopo aprovado em 11/09): (1) mapa + linha do tempo das
# intervencoes com fontes do DOU; (2) tempos T1-T4 por porto-mes com o
# marcador do PSP; (3) cobertura da informacao (T4) por porto-ano; (4)
# exportacao das amostras dos estimandos. Le SOMENTE o DuckDB auditado
# (read-only) e os registros versionados em data/metadata/.
suppressPackageStartupMessages({
  library(shiny); library(DBI); library(duckdb); library(data.table)
  library(ggplot2); library(leaflet); library(DT)
})
RAIZ <- normalizePath(if (file.exists("project.Rproj")) "." else "..", winslash = "/")
DB <- file.path(RAIZ, "data/processed/observatory.duckdb")
con <- dbConnect(duckdb(), DB, read_only = TRUE)
onStop(function() dbDisconnect(con, shutdown = TRUE))

portarias <- fread(file.path(RAIZ, "data/metadata/psp_portarias_dou.csv"), sep = ";", encoding = "UTF-8")
NOME_CDTUP <- c("Santos"="BRSSZ","Rio de Janeiro"="BRRIO","Vitória"="BRVIX","Fortaleza"="BRFOR",
  "Terminal Portuário de Pecém"="BRCE001","Recife"="BRREC","Suape"="BRSUA","Cabedelo"="BRCDO","Natal"="BRNAT",
  "Areia Branca"="BRARE","Maceió"="BRMCZ","Belém"="BRBEL","Itaqui"="BRIQI","Santana (Macapá)"="BRMCP",
  "Santarém"="BRSTM","Vila do Conde"="BRVDC","Manaus"="BRMAO","Paranaguá"="BRPNG","Antonina"="BRANT",
  "Rio Grande"="BRRIG","Porto Alegre"="BRPOA","Pelotas"="BRPET","São Sebastião"="BRSSO")
coortes <- portarias[, .(porto = trimws(unlist(strsplit(gsub(" e ", ", ", portos), ",")))),
                     by = .(portaria, data_ato, migracao_definitiva_ate, fonte)]
coortes[, cdtup := NOME_CDTUP[porto]]
coortes <- rbind(coortes, data.table(portaria = "SERPRO (notícia oficial)", data_ato = c("2011-08-01", "2011-08-15"),
  migracao_definitiva_ate = "", fonte = "serpro.gov.br", porto = c("Santos", "Rio de Janeiro"), cdtup = c("BRSSZ", "BRRIO")))
coortes <- coortes[!is.na(cdtup)][!duplicated(cdtup)]
ports <- as.data.table(dbGetQuery(con, "SELECT * FROM ports"))
ports[, c("lon", "lat") := tstrsplit(coordenadas, ",", fixed = TRUE)]
ports[, `:=`(lon = as.numeric(lon), lat = as.numeric(lat))]
ports <- merge(ports, coortes[, .(cdtup, data_psp = data_ato, portaria)], by = "cdtup", all.x = TRUE)
publicos <- ports[tipo_autoridade == "Porto Público" & !is.na(lat)][order(porto)]

ui <- navbarPage("Brazilian Port Digital Transformation Observatory",
  tabPanel("1. Intervenções",
    fluidRow(column(7, leafletOutput("mapa", height = 520)),
             column(5, h4("Portarias SEP do Porto Sem Papel (íntegras do DOU)"), DTOutput("tab_portarias")))),
  tabPanel("2. Tempos operacionais",
    sidebarLayout(
      sidebarPanel(
        selectInput("porto", "Porto público", setNames(publicos$cdtup, publicos$porto), selected = "BRSSZ"),
        checkboxGroupInput("tempos", "Componentes (mediana mensal, horas)",
          c("T1 espera p/ atracação" = "t1", "T2 atracado→início op." = "t2",
            "T4 término op.→desatracação" = "t4", "TA atracado" = "ta"), selected = c("t1", "t2", "t4")),
        sliderInput("anos", "Período", 2010, 2026, c(2010, 2016), sep = ""), width = 3),
      mainPanel(plotOutput("serie", height = 460),
        helpText("Linha tracejada: data do ato que disciplinou o uso do Porto Sem Papel no porto. Descritivo — não é estimativa causal.")))),
  tabPanel("3. Qualidade da informação",
    plotOutput("cobertura", height = 640),
    helpText("Share de atracações com T4 registrado. A decomposição documental passa a ser reportada junto com a janela única nos maiores portos (H11).")),
  tabPanel("4. Exportar evidências",
    sidebarLayout(
      sidebarPanel(selectInput("amostra", "Amostra",
        c("Painel porto-mês (2010-2026)" = "pm",
          "Atracações dos portos datados, 2010-2013 (estimando E1)" = "calls",
          "Comércio URF×país×mês marítimo (estimando E5)" = "trade",
          "Registro de coortes do PSP" = "coortes")),
        downloadButton("baixar", "Baixar CSV"), width = 3),
      mainPanel(verbatimTextOutput("descricao"), DTOutput("previa"))))
)

server <- function(input, output, session) {
  output$mapa <- renderLeaflet({
    d <- ports[!is.na(lat) & tipo_autoridade == "Porto Público"]
    d[, coorte := fifelse(is.na(data_psp), "sem data", substr(data_psp, 1, 4))]
    pal <- colorFactor(c("#2c6fbb", "#c9a227", "#3f8f5a", "grey60"), levels = c("2011", "2012", "2013", "sem data"))
    leaflet(d) |> addProviderTiles("CartoDB.Positron") |>
      addCircleMarkers(~lon, ~lat, radius = 7, color = ~pal(coorte), fillOpacity = .85, stroke = FALSE,
        popup = ~sprintf("<b>%s</b><br>%s<br>PSP: %s<br>%s", porto, complexo,
                         fcoalesce(data_psp, "sem íntegra"), fcoalesce(portaria, ""))) |>
      addLegend("bottomright", pal = pal, values = ~coorte, title = "Coorte do PSP")
  })
  output$tab_portarias <- renderDT(portarias[, .(portaria, data_ato, portos, migracao_definitiva_ate)],
                                   options = list(pageLength = 10, dom = "tp"), rownames = FALSE)
  output$serie <- renderPlot({
    d <- as.data.table(dbGetQuery(con, sprintf("
      SELECT pc.ano, pc.mes, median(t.t1) t1, median(t.t2) t2, median(t.t4) t4, median(t.ta) ta
      FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
      WHERE pc.flag_mov_carga AND pc.cdtup = '%s' AND pc.ano BETWEEN %d AND %d GROUP BY 1,2",
      input$porto, input$anos[1], input$anos[2])))
    d[, data := as.Date(sprintf("%d-%02d-01", ano, mes))]
    l <- melt(d, id.vars = "data", measure.vars = input$tempos)
    p <- ggplot(l, aes(data, value, colour = variable)) + geom_line() +
      labs(x = NULL, y = "horas (mediana mensal)", colour = NULL, title = publicos[cdtup == input$porto, porto]) +
      theme_minimal(base_size = 12)
    dp <- coortes[cdtup == input$porto, data_ato]
    if (length(dp)) p <- p + geom_vline(xintercept = as.Date(dp), linetype = "dashed")
    p
  })
  output$cobertura <- renderPlot({
    cob <- as.data.table(dbGetQuery(con, "
      SELECT pc.cdtup, any_value(pc.porto) porto, pc.ano, AVG(CASE WHEN t.t4 IS NOT NULL THEN 1.0 ELSE 0 END) cob
      FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
      WHERE pc.flag_mov_carga AND pc.tipo_autoridade = 'Porto Público' AND pc.ano BETWEEN 2010 AND 2025 GROUP BY 1,3"))
    ggplot(cob, aes(factor(ano), reorder(porto, cob, mean), fill = cob)) + geom_tile(colour = "white") +
      scale_fill_gradient(low = "#f4f1ea", high = "#2c6fbb", labels = scales::percent) +
      labs(x = NULL, y = NULL, fill = "Cobertura de T4") + theme_minimal(base_size = 11)
  })
  amostra <- reactive({
    switch(input$amostra,
      pm = as.data.table(dbGetQuery(con, "SELECT * FROM port_month_panel")),
      calls = as.data.table(dbGetQuery(con, sprintf(
        "SELECT pc.*, t.t1, t.t2, t.t3, t.t4, t.ta, t.te FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
         WHERE pc.flag_mov_carga AND pc.ano BETWEEN 2010 AND 2013 AND pc.cdtup IN (%s)",
        paste(sprintf("'%s'", coortes$cdtup), collapse = ",")))),
      trade = as.data.table(dbGetQuery(con, "SELECT * FROM trade_urf_country")),
      coortes = coortes)
  })
  output$descricao <- renderText(sprintf("%s linhas × %d colunas. Fonte: observatory.duckdb (auditado; ver docs/data_dictionary.md).",
                                         format(nrow(amostra()), big.mark = "."), ncol(amostra())))
  output$previa <- renderDT(head(amostra(), 200), options = list(scrollX = TRUE, pageLength = 10, dom = "tp"), rownames = FALSE)
  output$baixar <- downloadHandler(
    filename = function() sprintf("observatorio_%s_%s.csv", input$amostra, Sys.Date()),
    content = function(f) fwrite(amostra(), f))
}
shinyApp(ui, server)
