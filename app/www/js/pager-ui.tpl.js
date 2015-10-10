// delegate a click event handler for pager page-number buttons
$(document).on("click", "#{{pager}} button.page-num-button", function() {
  var page_num = $(this).data("page-num");
  $("#{{pager}} .page-current").val(page_num);
  $("#{{pager}} .page-current").change();
});

$(document).on("click", "#{{pager}} button.page-prev-button", function() {
  var page_num_current = parseInt($("#{{pager}} .page-current").val());

  if (page_num_current > 1) {
    $("#{{pager}} .page-current").val(page_num_current-1);
    $("#{{pager}} .page-current").change();
  }

});

$(document).on("click", "#{{pager}} button.page-next-button", function() {
  var page_num_current = parseInt($("#{{pager}} .page-current").val());
  var pages_total = parseInt($("#{{pager}} .pages-total").val());

  if (page_num_current < pages_total) {
    $("#{{pager}} .page-current").val(page_num_current+1);
    $("#{{pager}} .page-current").change();
  }

});

// delegate a change event handler for pages-total to draw the page buttons
$(document).on("change", "#{{pager}} input.pages-total", function() {
  draw_page_buttons("#{{pager}}");
});

// delegate a change event handler for page-current to draw the page buttons
$(document).on("change", "#{{pager}} input.page-current", function() {
  draw_page_buttons("#{{pager}}");
});

/**
 * Render pager-ui buttons
 * @param target - selector string or jQuery object representation of pager-ui
 *    container node
 * @param {number} [page_current] - current page number (1-based). If undefined
 *    the value of a input element that is a child of target with class
 *    .page-current is used.
 * @param {number} [pages_total] - total number of pages. If undefined
 *    the value of a input element that is a child of target with class
 *    .pages-total is used.
 *
 * Requires Underscore.js
 *
 */
draw_page_buttons = function(target, page_current, pages_total) {
  var $target = $(target);
  var $btn_group = $target.find(".page-button-group-numbers");

  if (typeof page_current === "undefined") {
    page_current = parseInt($target.find("input.page-current").val());
  }

  if (typeof pages_total === "undefined") {
    pages_total = parseInt($target.find("input.pages-total").val());
  }

  // clear any pre-existing buttons
  $btn_group.html("");

  // test if anything should be rendered at all
  if (!pages_total) {
    $btn_group.append(
      $("<span />").addClass("text-muted").html("no pages")
    );
    return;
  }

  // create a button template
  var $btn_tpl = $("<button />").addClass('btn btn-default');

  // create a "..." spacer button
  var $btn_dots = $btn_tpl.clone()
    .attr('disabled', 'disabled')
    .html('...');

  // determine what range (hi/med/low) the current page is in
  var show_lo_dots = !_.contains(_.range(1,4), page_current);
  var show_hi_dots = !_.contains(_.range(pages_total-2, pages_total+1), page_current);

  // create an array of all page number buttons to slice for button sets
  var $btn_nums = [];
  for (var i=1; i<=pages_total; i++) {
    var $btn_num = $btn_tpl.clone()
      .attr('data-page-num', i)
      .addClass('page-num-button')
      .html(i);

    if (i == page_current) {
      $btn_num
        .attr('disabled', 'disabled')
        .removeClass('btn-default')
        .addClass('btn-info');
    }

    $btn_nums.push($btn_num);
  }

  // utility functions for rendering button sets
  // - a numeric comparison function for Array.sort()
  // - an iteratee for _.map to retrieve page num buttons
  var NumericAscending = function(a,b){return a-b};
  var GetPageNumButton = function(page_num){return $btn_nums[page_num - 1]};

  // render the page number buttons
  if (pages_total <= 10) {
    // show all buttons
    $btn_group.append($btn_nums);

  } else {
    var $btn_set = [];
    if ( show_lo_dots &&  show_hi_dots) {
      // mid-range button set
      // [1] ... [p-1][p][p+1] ... [N]
      $btn_set = $btn_set
        .concat([
          $btn_nums[0],
          $btn_dots.clone()
        ])
        .concat(_.map(
          _.range(page_current-1, page_current+2),  // [-1,+1] current page
          GetPageNumButton
        ))
        .concat([
          $btn_dots.clone(),
          $btn_nums[pages_total-1]
        ]);

    } else
    if (!show_lo_dots &&  show_hi_dots) {
      // lo-range button set
      // [1][2][3] ... [N]
      $btn_set = $btn_set
        .concat(_.map(
          _.union(_.range(1, 4), [page_current + 1])
            .sort(NumericAscending),  // [1, current page + 1]
          GetPageNumButton
        ))
        .concat([
          $btn_dots.clone(),
          $btn_nums[pages_total-1]
        ]);

    } else
    if ( show_lo_dots && !show_hi_dots) {
      // hi-range button set
      // [1] ... [N-2][N-1][N]
      $btn_set = $btn_set
        .concat([
          $btn_nums[0],
          $btn_dots.clone()
        ])
        .concat(_.map(
          _.union(_.range(pages_total-2, pages_total+1), [page_current - 1])
            .sort(NumericAscending),  // [current page - 1, pages_total]
          GetPageNumButton
        ));

    }

    $btn_group.append($btn_set);
  }

};
