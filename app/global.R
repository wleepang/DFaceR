library(shiny)
library(aplpack)

label_data = function(data) {
  if (is.null(data)) {
    return(NULL)
  }

  col_classes = sapply(data, class)
  cols_char = which(sapply(data, inherits, what='character'))

  labels = NULL
  if (length(cols_char)) {
    if (length(cols_char) > 1) {
      labels = do.call(paste, c(as.list(data[,cols_char]), sep=', '))
    } else {
      labels = data[[cols_char]]
    }
  }

  return(labels)
}

clean_data = function(data) {
  # faces expects a data.matrix-like object with all numeric columns

  if (is.null(data)) {
    return(NULL)
  }

  col_classes = sapply(data, class)
  cols_char = which(sapply(data, inherits, what='character'))
  cols_fctr = which(sapply(data, inherits, what='factor'))

  # try to preserve character columns as labels (row.names)
  if (length(cols_char)) {

    tryCatch({
        row_names = if (length(cols_char) > 1) {
          do.call(paste, c(as.list(data[,cols_char]), sep=', '))
        } else {
          data[[cols_char]]
        }
        rownames(data) = row_names

      },
      error = function(e) {
        # unable to parse rownames, drop completely
        message(sprintf('unable to assign row names: %s', e$message))
      },
      finally = {
        data = data[-cols_char]
      }
    )

  }

  # convert factor columns to integer
  if (length(cols_fctr)) {
    data[,cols_fctr] = sapply(data[,cols_fctr], as.integer)
  }

  return(data)
}

scale_data = function(data) {
  # normalizes data to [-1,1]
  apply(data, 2, function(x) {
    (x - min(x)) / (max(x) - min(x)) * 2 - 1
  })
}

pagerInputUI = function(inputId) {
  # get javascript template
  js = includeText('www/js/pager-ui.tpl.js')

  # replace template inputId with supplied inputId
  js = gsub('{{pager}}', inputId, js, fixed = T)

  # construct the pager-ui framework
  tagList(
    singleton(
      tags$head(
        tags$script(src = 'js/underscore-min.js'),
        tags$script(HTML(js))
      )
    ),

    # root pager-ui node
    div(
      id = inputId,
      class = 'pager-ui',

      # reactive numeric input to store current page
      # access it as input[['{{inputId}}__page_current']]
      span(
        class = 'hidden shiny-input-container',
        tags$input(
          id = paste(inputId, 'page_current', sep='__'),
          class = 'page-current',
          type = 'number', value = 1, min = 1
        )
      ),

      # reactive numeric input to store total pages
      # access it as input[['{{inputId}}__pages_total']]
      span(
        class = 'hidden shiny-input-container',
        tags$input(
          id = paste(inputId, 'pages_total', sep='__'),
          class = 'pages-total',
          type = 'number', value = 0, min = 0
        )
      ),

      # container for pager button groups
      div(
        class = 'page-buttons',

        # prev/next buttons
        span(
          class = 'page-button-group-prev-next btn-group',
          tags$button(
            id = paste(inputId, 'page-prev-button', sep='__'),
            class = 'page-prev-button btn btn-default',
            'Prev'
          ),
          tags$button(
            id = paste(inputId, 'page-next-button', sep='__'),
            class = 'page-next-button btn btn-default',
            'Next'
          )
        ),

        # page number buttons
        # dynamically generated via javascript
        span(
          class = 'page-button-group-numbers btn-group'
        )
      )
    )
  )
}
