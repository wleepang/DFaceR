// delegate a click event handler for pager page-number buttons
$(document).on("click", "#{{pager_buttons}} button.page-num-button", function() {
  var page_num = $(this).data("page-num");
  $("#{{num_current_page}}").val(page_num);
  $("#{{num_current_page}}").change();
});
