var Ppd = function() {
  var init = function() {
    initControls();
    bindEvents();
  };

  var initControls = function() {
    console.log( "Setting datepicker on " + $(".date-picker").length);
    $(".date-picker").datepicker( {
      dateFormat: "yy-mm-dd",
      changeMonth: true,
      changeYear: true
    } );
  };

  var bindEvents = function() {

  };

  return {
    init: init
  };
}();

