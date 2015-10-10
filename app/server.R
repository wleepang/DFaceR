
shinyServer(function(input, output, session) {

  data = reactiveValues(raw = NULL, clean = NULL, labels = NULL, tmp = NULL, page = NULL)
  pager = reactiveValues(
    total_pages = 1,
    current_page = 1,
    page_rows = NULL
  )

  observe(
    label = 'observe_data_pages',
    x = {
      # (re)initializes the pager on data load or if the number of faces per
      # page is changed.
      if (!is.null(data$clean)) {
        pager$total_pages = ceiling(nrow(data$clean) / input$num_faces_per_page)

        if (pager$current_page > pager$total_pages) {
          pager$current_page = pager$total_pages
          session$sendInputMessage('pager_ui__page_current', list(value = pager$current_page))
        }

        row_starts = seq(1, nrow(data$clean), by = input$num_faces_per_page)
        row_stops  = c(row_starts[-1] - 1, nrow(data$clean))
        pager$page_rows = mapply(`:`, row_starts, row_stops, SIMPLIFY=F)

        session$sendInputMessage('pager_ui__pages_total', list(value = pager$total_pages))
      }
    }
  )

  # monitor the hidden numeric field that stores the current page
  # re-rendering the pager-ui is handled by javascript event handlers
  observeEvent(
    eventExpr = {
      input$pager_ui__page_current
    },
    handlerExpr = {
      pager$current_page = input$pager_ui__page_current
    }
  )

  observeEvent(
    eventExpr = {
      input$btn_draw
    },
    handlerExpr = {
      # parse raw data into scaled "clean" data
      # i.e. data where columns are converted to numeric values and normalized
      # to values within [-1,1]
      #
      # convert any columns that are specified as labels to character()
      data$tmp = data$raw
      if (input$sel_labels_from == 'variables' && length(input$sel_label_vars)) {
        data$tmp[input$sel_label_vars] = lapply(
          data$tmp[input$sel_label_vars],
          as.character
        )
      }

      data$labels = label_data(data$tmp)
      data$clean = scale_data(clean_data(data$tmp))

      if (is.null(rownames(data$clean))) {
        rownames(data$clean) = as.character(1:nrow(data$clean))
      }

      pager$current_page = 1
      pager$total_pages = ceiling(nrow(data$clean) / input$num_faces_per_page)
    }
  )

  observeEvent(
    eventExpr = {
      input$sel_dataset
    },
    handlerExpr = {
      sel_dataset = input$sel_dataset
      if (sel_dataset != 'custom') {
        if (sel_dataset == 'mtcars') {
          data$raw = mtcars
        } else if (sel_dataset == 'iris') {
          data$raw = iris
        } else {
          data$raw = NULL
        }
      } else {
        data$raw = NULL
      }

      if (!is.null(data$raw)) {
        updateSelectInput(session, 'sel_label_vars', choices = colnames(data$raw))
      }
    }
  )

  observeEvent(
    eventExpr = {
      input$file_data
    },
    handlerExpr = {
      file = as.list(input$file_data[1,])
      data$raw = read.csv(file$datapath, check.names=F)
      updateSelectInput(session, 'sel_label_vars', choices = colnames(data$raw))
    }
  )

  dfaces = reactive({
    if (is.null(data$clean)) {
      return(NULL)
    }

    data$page = data$clean[pager$page_rows[[pager$current_page]],,drop=F]

    if (!is.null(data$labels)) {
      labels = data$labels[pager$page_rows[[pager$current_page]]]
      faces(data$page, labels = labels, scale=F, plot.faces=F, print.info=F)
    } else {
      faces(data$page, scale=F, plot.faces=F, print.info=F)
    }

  })

  plot_ht = reactive(input$num_plot_height)
  plot_wd = reactive(input$num_plot_width)

  output$table_face_mappings = renderPrint({
    if (!is.null(data$clean)) {
      info = sub('(.*?)\\s*$', '\\1', dfaces()$info)
      data.frame(info, check.names = F)
    }
  })
  output$plot_faces = renderPlot({
    if (is.null(dfaces())) {
      return(NULL)
    }

    fo = dfaces()
    par(mai=c(0,0,0,0), cex=0.7)
    plot(fo, width = plot_ht()/plot_wd())
  },
  width = function(){plot_wd()},
  height = function(){plot_ht()},
  res = 96)

})
