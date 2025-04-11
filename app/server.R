server <- function(input, output, session) {
    # Reactive value to store sequences
    sequences <- reactiveVal(NULL)
    
    # Reactive value to store alignment results
    alignment_result <- reactiveVal(NULL)
    
    # Reactive value to store the PDF path
    pdf_path <- reactiveVal(NULL)
    
    # Function to format sequence for display
    formatSequence <- function(seq, name, width = 60) {
        seq_str <- as.character(seq)
        seq_len <- nchar(seq_str)
        
        # Format header
        result <- sprintf(">%s (length: %d)\n", name, seq_len)
        
        # Format sequence with line breaks
        for(i in seq(1, seq_len, by = width)) {
            end <- min(i + width - 1, seq_len)
            result <- paste0(result, substr(seq_str, i, end), "\n")
        }
        return(result)
    }
    
    # Function to parse FASTA text
    parseFastaText <- function(text) {
        # Check if text is empty or doesn't contain FASTA format
        if (is.null(text) || !grepl(">", text)) {
            return(NULL)
        }
        
        # Create a temporary file
        temp <- tempfile(fileext = ".fasta")
        # Ensure text ends with newline
        if (!endsWith(text, "\n")) {
            text <- paste0(text, "\n")
        }
        # Write the text to temp file
        writeLines(text, temp)
        
        # Read the temporary file
        seqs <- tryCatch({
            if (input$seqType == "protein") {
                readAAStringSet(temp)
            } else {
                readDNAStringSet(temp)
            }
        }, error = function(e) {
            showNotification(
                "Error parsing sequences. Please ensure the input is in valid FASTA format.",
                type = "error"
            )
            NULL
        }, finally = {
            # Clean up
            unlink(temp)
        })
        
        return(seqs)
    }
    
    # Handle file input
    observeEvent(input$seqFile, {
        req(input$seqFile)
        
        seqs <- tryCatch({
            # Read the file content
            if (input$seqType == "protein") {
                readAAStringSet(input$seqFile$datapath)
            } else {
                readDNAStringSet(input$seqFile$datapath)
            }
        }, error = function(e) {
            showNotification(
                "Error reading sequences. Please ensure the file is in FASTA format.",
                type = "error"
            )
            NULL
        })
        
        if (!is.null(seqs)) {
            sequences(seqs)
        }
    })
    
    # Handle text input
    observeEvent(input$seqText, {
        req(input$seqText)
        text <- input$seqText
        if (nchar(trimws(text)) > 0) {
            seqs <- parseFastaText(text)
            if (!is.null(seqs) && length(seqs) > 0) {
                sequences(seqs)
            }
        }
    })
    
    # Preview sequences
    output$seqPreview <- renderPrint({
        if (!is.null(sequences()) && length(sequences()) > 0) {
            seqs <- sequences()
            cat("Loaded Sequences:\n\n")
            for(i in seq_along(seqs)) {
                cat(formatSequence(seqs[[i]], names(seqs)[i]))
                cat("\n")
            }
        } else {
            cat("No sequences loaded yet.\n\nExample FASTA format:\n\n>sequence1\nACGT\n>sequence2\nACGT")
        }
    })
    
    # Perform alignment when button is clicked
    observeEvent(input$runMSA, {
        req(sequences())
        if (length(sequences()) < 2) {
            showNotification(
                "At least two sequences are required for alignment.",
                type = "error"
            )
            return()
        }
        
        withProgress(message = 'Performing alignment...', value = 0, {
            tryCatch({
                # Perform alignment with parameters
                result <- msa(sequences(),
                            type = input$seqType,
                            method = input$method,
                            gapOpening = input$gapOpening,
                            gapExtension = input$gapExtension,
                            maxiters = input$maxiters)
                
                alignment_result(result)
                
                # Use a simple fixed path in the working directory
                output_pdf <- "alignment_result.pdf"
                
                # Generate PDF with msaPrettyPrint
                tryCatch({
                    # Prepare parameters based on conservation selection
                    show_conservation <- "conservation" %in% input$visOptions
                    print_params <- list(
                        output = "pdf",
                        file = output_pdf,
                        showNames = input$namesPos,
                        showLogo = if (show_conservation) "top" else "none",
                        showConsensus = if ("consensus" %in% input$visOptions) "bottom" else "none",
                        showLegend = "legend" %in% input$visOptions,
                        consensusColors = input$consensusColors,
                        shadingMode = input$shadingMode,
                        shadingColors = input$colorScheme,
                        askForOverwrite = FALSE
                    )
                    
                    # Only add logoColors if conservation is enabled
                    if (show_conservation) {
                        print_params$logoColors = input$conservationColors
                    }
                    
                    # Call msaPrettyPrint with the prepared parameters
                    do.call(msaPrettyPrint, c(list(result), print_params))
                    
                    # If PDF was created successfully
                    if (file.exists(output_pdf)) {
                        # Update PDF path
                        pdf_path(output_pdf)
                        
                        # Switch to Alignment Results tab
                        updateTabsetPanel(session, "mainTabset", selected = "Alignment Results")
                        
                        # Show success message
                        showNotification(
                            "Alignment complete! Results are displayed below.",
                            type = "message"
                        )
                    } else {
                        stop("Failed to generate PDF file")
                    }
                }, error = function(e) {
                    message("Error details: ", e$message)
                    message("Working directory: ", getwd())
                    showNotification(
                        paste("Error generating PDF:", e$message),
                        type = "error"
                    )
                })
            }, error = function(e) {
                showNotification(
                    paste("Error in alignment:", e$message),
                    type = "error"
                )
            })
        })
    })
    
    # PDF viewer output
    output$pdfviewer <- renderUI({
        req(pdf_path())
        
        tryCatch({
            if (!file.exists(pdf_path())) {
                return(tags$div(
                    style = "color: red; padding: 20px;",
                    tags$h4("PDF file not found"),
                    tags$p("Path checked: ", pdf_path()),
                    tags$p("Working directory: ", getwd()),
                    tags$p("Please try running the alignment again.")
                ))
            }
            
            # Convert PDF to base64
            pdf_content <- base64enc::base64encode(pdf_path())
            
            # Display PDF using base64 data URI
            tags$iframe(
                src = paste0("data:application/pdf;base64,", pdf_content),
                width = "100%",
                height = "800px",
                style = "border: none;"
            )
        }, error = function(e) {
            tags$div(
                style = "color: red; padding: 20px;",
                tags$h4("Error displaying PDF:"),
                tags$p(e$message),
                tags$p("Please try downloading the PDF instead.")
            )
        })
    })
    
    # Download handlers
    output$downloadPDF <- downloadHandler(
        filename = function() {
            paste0("alignment_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf")
        },
        content = function(file) {
            req(alignment_result())
            # If we already have a PDF file, just copy it
            if (file.exists(pdf_path())) {
                file.copy(pdf_path(), file)
            } else {
                # Otherwise generate a new one
                # Prepare parameters based on conservation selection
                show_conservation <- "conservation" %in% input$visOptions
                print_params <- list(
                    output = "pdf",
                    file = file,
                    showNames = input$namesPos,
                    showLogo = if (show_conservation) "top" else "none",
                    showConsensus = if ("consensus" %in% input$visOptions) "bottom" else "none",
                    showLegend = "legend" %in% input$visOptions,
                    consensusColors = input$consensusColors,
                    shadingMode = input$shadingMode,
                    shadingColors = input$colorScheme,
                    askForOverwrite = FALSE
                )
                
                # Only add logoColors if conservation is enabled
                if (show_conservation) {
                    print_params$logoColors = input$conservationColors
                }
                
                # Call msaPrettyPrint with the prepared parameters
                do.call(msaPrettyPrint, c(list(alignment_result()), print_params))
            }
        },
        contentType = "application/pdf"
    )
    
    output$downloadFasta <- downloadHandler(
        filename = function() {
            paste0("alignment_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".fasta")
        },
        content = function(file) {
            req(alignment_result())
            writeXStringSet(as(alignment_result(), "XStringSet"), file)
        }
    )
    
    # Track visitor on session start
    observe({
        # Get visitor IP
        ip <- session$request$REMOTE_ADDR
        
        # Get IP info
        ip_info <- get_ip_info(ip)
        
        if (!is.null(ip_info)) {
            # Connect to database
            con <- dbConnect(SQLite(), db_path)
            on.exit(dbDisconnect(con))
            
            # Insert visitor info
            query <- sprintf("
                INSERT INTO visitors (ip, country, city, latitude, longitude)
                VALUES ('%s', '%s', '%s', %f, %f)
            ", ip, ip_info$country, ip_info$city, ip_info$lat, ip_info$lon)
            
            dbExecute(con, query)
        }
    })
    
    # Visitor counter
    output$visitorCount <- renderText({
        # Connect to database
        con <- dbConnect(SQLite(), db_path)
        on.exit(dbDisconnect(con))
        
        # Get total number of visits
        total_visits <- dbGetQuery(con, "SELECT COUNT(*) as count FROM visitors")$count
        
        # Format the number with commas
        format(total_visits, big.mark = ",")
    })
    
    # Visitor map
    output$visitor_map <- renderLeaflet({
        # Connect to database
        con <- dbConnect(SQLite(), "visitors.db")
        on.exit(dbDisconnect(con))
        
        # Get visitor data
        visitors <- dbGetQuery(con, "
            SELECT DISTINCT country, city, latitude, longitude, COUNT(*) as visits
            FROM visitors
            GROUP BY country, city
            ORDER BY visits DESC
        ")
        
        # Create map
        leaflet(visitors) %>%
            addTiles() %>%  # Add default OpenStreetMap tiles
            addCircleMarkers(
                ~longitude, ~latitude,
                radius = ~sqrt(visits) * 5,
                popup = ~paste0(
                    "<strong>", city, ", ", country, "</strong><br>",
                    "Visits: ", visits
                ),
                fillOpacity = 0.7,
                color = "#2c3e50",
                fillColor = "#3498db"
            )
    })
    
    # Visitor statistics
    output$visitorStats <- renderText({
        # Connect to database
        con <- dbConnect(SQLite(), "visitors.db")
        on.exit(dbDisconnect(con))
        
        # Get statistics
        total_visits <- dbGetQuery(con, "SELECT COUNT(*) as count FROM visitors")$count
        unique_countries <- dbGetQuery(con, "SELECT COUNT(DISTINCT country) as count FROM visitors")$count
        unique_cities <- dbGetQuery(con, "SELECT COUNT(DISTINCT city) as count FROM visitors")$count
        
        sprintf(
            "Total Visits: %d | Unique Countries: %d | Unique Cities: %d",
            total_visits, unique_countries, unique_cities
        )
    })
} 