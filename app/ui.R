
shinyUI(pageWithSidebar(

  # Application title
  headerPanel(
    windowTitle = 'DFaceR',
    title = "DFaceR: Visualize multidimensional data with faces"
  ),

  sidebarPanel(
    width = 3,

    # data selection input, either a built-in set (mtcars, iris)
    # or an uploaded csv
    helpText('1. choose sample data or upload your own'),
    selectInput('sel_dataset', 'Dataset', choices=c('mtcars', 'iris', 'upload ...'='upload')),
    conditionalPanel(
      'input.sel_dataset == "upload"',
      fileInput('file_data', 'Data File', accept = 'text/csv')
    ),

    # user selected labels, either rownames (if they exist)
    # or paste()'d variables
    helpText('2. select how faces are labeled'),
    selectInput('sel_labels_from', 'labels from', choices=c('row names', 'variables ...'='variables')),
    conditionalPanel(
      'input.sel_labels_from == "variables"',
      selectInput('sel_label_vars', NULL, multiple = T, choices = NULL)
    ),

    actionButton('btn_draw', 'Draw Faces', icon = icon('smile-o'), class='btn-primary'),
    tags$hr(),
    div(
      div(
        class = 'row',
        span(
          class = 'col-xs-4',
          numericInput('num_faces_per_page', '# / page', value = 100, min = 1)
        ),
        span(
          class = 'col-xs-4',
          numericInput('num_plot_width', 'plot wd', value = 800, min = 400, step = 10)
        ),
        span(
          class = 'col-xs-4',
          numericInput('num_plot_height', 'plot ht', value = 600, min = 400, step = 10)
        )
      )
    ),
    tags$hr(),
    tags$label('features', `for`='table_face_mappings'),
    verbatimTextOutput('table_face_mappings')
  ),

  mainPanel(
    pagerInputUI('pager_ui'),
    plotOutput("plot_faces")
  )
))
