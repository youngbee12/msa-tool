ui <- fluidPage(
    # Custom CSS
    tags$head(
        tags$style(HTML("
            .content-wrapper {
                margin: 20px;
                max-width: 1200px;
                margin-left: auto;
                margin-right: auto;
            }
            .visitor-counter {
                text-align: center;
                padding: 15px;
                margin-bottom: 20px;
                background-color: #f8f9fa;
                border: 1px solid #ddd;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            }
            .visitor-counter h2 {
                margin: 0;
                color: #2c3e50;
                font-size: 24px;
            }
            .visitor-counter .number {
                font-size: 36px;
                font-weight: bold;
                color: #3498db;
                margin: 10px 0;
            }
            .well {
                background-color: #f8f9fa;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .sequence-input {
                width: 100%;
                min-height: 200px;
                font-family: monospace;
                padding: 8px;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            .download-panel {
                margin-top: 20px;
                padding: 15px;
                background-color: #f8f9fa;
                border-radius: 8px;
                text-align: center;
            }
            .download-panel .btn {
                margin: 5px;
            }
            #pdfviewer {
                width: 100%;
                height: 800px;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            .param-section {
                margin-top: 15px;
                padding: 10px;
                border: 1px solid #eee;
                border-radius: 4px;
            }
            .param-section h4 {
                color: #2c3e50;
                margin-bottom: 15px;
            }
            #visitor_map {
                height: 600px;
                width: 100%;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            .map-info {
                margin: 20px 0;
                padding: 15px;
                background-color: #f8f9fa;
                border-radius: 8px;
            }
        "))
    ),
    
    # Application title
    titlePanel("Multiple Sequence Alignment Tool"),
    
    # Visitor Counter
    div(class = "visitor-counter",
        h2("Welcome! You are visitor number"),
        div(class = "number", textOutput("visitorCount"))
    ),
    
    div(class = "content-wrapper",
        sidebarLayout(
            sidebarPanel(
                # Input method selection
                radioButtons("inputMethod", "Choose Input Method:",
                           choices = c("Upload File" = "file",
                                     "Paste Sequences" = "text"),
                           selected = "text"),
                
                # File input (shown when file method is selected)
                conditionalPanel(
                    condition = "input.inputMethod == 'file'",
                    fileInput("seqFile", "Upload FASTA File",
                             multiple = FALSE,
                             accept = c(".fasta", ".fa", ".txt"))
                ),
                
                # Text input (shown when text method is selected)
                conditionalPanel(
                    condition = "input.inputMethod == 'text'",
                    tags$div(
                        tags$p("Enter sequences in FASTA format:"),
                        tags$p("Example:"),
                        tags$pre(
                            ">sequence1\nACGT\n>sequence2\nACGT"
                        ),
                        tags$textarea(
                            id = "seqText",
                            class = "sequence-input",
                            placeholder = "Paste your FASTA sequences here..."
                        )
                    )
                ),
                
                # MSA Parameters
                div(class = "param-section",
                    h4("MSA Parameters"),
                    # Sequence type selection
                    radioButtons("seqType", "Sequence Type:",
                               choices = c("Protein" = "protein",
                                         "DNA" = "dna"),
                               selected = "protein"),
                    
                    # Method selection
                    selectInput("method", "Alignment Method:",
                              choices = c("ClustalW" = "ClustalW",
                                        "Muscle" = "Muscle",
                                        "ClustalOmega" = "ClustalOmega"),
                              selected = "ClustalW"),
                    
                    # Gap opening penalty
                    numericInput("gapOpening", "Gap Opening Penalty:",
                               value = 10, min = 1, max = 100),
                    
                    # Gap extension penalty
                    numericInput("gapExtension", "Gap Extension Penalty:",
                               value = 0.2, min = 0, max = 10, step = 0.1),
                    
                    # Maximum iterations
                    numericInput("maxiters", "Maximum Iterations:",
                               value = 16, min = 1, max = 100)
                ),
                
                # Pretty Print Parameters
                div(class = "param-section",
                    h4("Visualization Parameters"),
                    
                    # Basic options
                    checkboxGroupInput("visOptions", "Display Options:",
                                     choices = c("Show Consensus" = "consensus",
                                               "Show Conservation" = "conservation",
                                               "Show Legend" = "legend"),
                                     selected = c("consensus", "legend")),
                    
                    # Names position
                    selectInput("namesPos", "Names Position:",
                              choices = c("Left" = "left",
                                        "Top" = "top",
                                        "None" = "none"),
                              selected = "left"),
                    
                    # Shading mode
                    selectInput("shadingMode", "Shading Mode:",
                              choices = c("Similar" = "similar",
                                        "Identical" = "identical",
                                        "Functional" = "functional",
                                        "Structure" = "structure"),
                              selected = "similar"),
                    
                    # Color scheme
                    selectInput("colorScheme", "Color Scheme:",
                              choices = c("Blues" = "blues",
                                        "Reds" = "reds",
                                        "Greens" = "greens",
                                        "Greys" = "greys",
                                        "BW" = "black"),
                              selected = "blues"),
                    
                    # Consensus colors
                    selectInput("consensusColors", "Consensus Colors:",
                              choices = c("ColdHot" = "ColdHot",
                                        "HotCold" = "HotCold",
                                        "BlueRed" = "BlueRed",
                                        "RedBlue" = "RedBlue"),
                              selected = "ColdHot"),
                    
                    # Conservation colors (only shown when conservation is selected)
                    conditionalPanel(
                        condition = "input.visOptions.includes('conservation')",
                        selectInput("conservationColors", "Conservation Colors:",
                                  choices = c("Structure" = "structure",
                                            "Hydrophobicity" = "hydrophobicity",
                                            "Chemistry" = "chemistry",
                                            "Rasmol" = "rasmol"),
                                  selected = "structure")
                    )
                ),
                
                # Action button
                actionButton("runMSA", "Run Alignment",
                           class = "btn-primary",
                           style = "width: 100%")
            ),
            
            mainPanel(
                tabsetPanel(id = "mainTabset",
                    tabPanel("Input Sequences",
                             verbatimTextOutput("seqPreview")),
                    tabPanel("Alignment Results",
                            div(class = "download-panel",
                                h4("Alignment Results"),
                                uiOutput("pdfviewer"),
                                hr(),
                                h4("Download Options"),
                                downloadButton("downloadPDF", "Download PDF", class = "btn-primary"),
                                downloadButton("downloadFasta", "Download FASTA", class = "btn-info")
                            ))
                )
            )
        )
    )
) 