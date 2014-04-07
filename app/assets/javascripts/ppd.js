var Ppd = function() {
  var init = function() {
    initControls();
    bindEvents();
  };

  var initControls = function() {
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

$( Ppd.init );
