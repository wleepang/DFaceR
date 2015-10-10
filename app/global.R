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

pagerCurrentPageNumber = function(inputId, pagerId) {
  # get javascript template
  js = includeText('www/js/pager.tpl.js')

  # replace template inputId with supplied inputId
  # replace template pagerId with supplied pagerId
  js = gsub('{{num_current_page}}', inputId, js, fixed = T)
  js = gsub('{{pager_buttons}}', pagerId, js, fixed = T)

  tagList(
    singleton(
      tags$head(tags$script(js))
    ),
    span(
      class = 'hidden shiny-input-container',
      tags$input(
        id = inputId,
        type = 'number', value = 1
      )
    )
  )
}
pagerInput = function(inputId, num_pages = 1, current_page = 1) {
  if (num_pages == 1 || is.null(num_pages)) {
    return(NULL)
  }

  if (is.null(current_page)) {
    current_page = 1
  }

  # create the full set of page-number buttons
  page_nums = lapply(
    seq(1, num_pages, by=1),
    function(n) {
      btn_class = 'page-num-button btn'
      disabled = NULL
      if (n == current_page) {
        btn_class = c(btn_class, 'btn-info')
        disabled = 'disabled'
      } else {
        btn_class = c(btn_class, 'btn-default')
      }

      actionButton(
        paste0('btn_pager_page_', n),
        n,
        class = paste(btn_class, collapse = ' '),
        disabled = disabled,
        `data-page-num` = n
      )
    }
  )

  # create a `...` disabled button that will be used as a spacer
  page_dots = actionButton(
    'btn_pager_dots', '...', class = 'btn btn-default', disabled = 'disabled'
  )

  # create a list of displayed page number buttons and `...` buttons
  # based on the number of pages available and the current page
  if (num_pages <= 5) {
    # show all pages if there are only a couple pages
    page_btns = page_nums
  } else if (current_page %in% 1:3) {
    # show first three pages ... last page
    page_btns = tagList(
      page_nums[union(1:3, current_page + 1)],
      page_dots,
      page_nums[num_pages]
    )
  } else if (current_page %in% (num_pages-2):(num_pages)) {
    # show first page ... last three pages
    page_btns = tagList(
      page_nums[1],
      page_dots,
      page_nums[union(current_page - 1, (num_pages-2):(num_pages))]
    )
  } else {
    # show first page ... current page -1,+1 ... last page
    page_btns = tagList(
      page_nums[1],
      page_dots,
      page_nums[(current_page-1):(current_page+1)],
      page_dots,
      page_nums[num_pages]
    )
  }

  page_prev = actionButton(
    'btn_pager_prev', 'Prev', class = 'page-prev-button btn btn-default')
  page_next = actionButton(
    'btn_pager_next', 'Next', class = 'page-next-button btn btn-default')

  # the final set of tags returned
  div(
    id = inputId,
    div(
      class = 'btn-group',
      tagList(
        page_prev,
        page_next
      )
    ),
    div(
      class = 'btn-group',
      tagList(
        page_btns
      )
    )
  )
}
updatePagerInput = function(pager) {
  num_pages = pager$total_pages
  current_page = pager$current_page

  renderUI(pagerInput(num_pages, current_page))
}
