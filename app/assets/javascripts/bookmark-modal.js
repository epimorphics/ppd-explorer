document.addEventListener("DOMContentLoaded",  function () {
  var focusableElements = 'input, .btn, .close'
  var modal = document.querySelector('#bookmark-dialog');
  var firstFocusableElement = modal.querySelectorAll(focusableElements)[0];
  var focusableContent = modal.querySelectorAll(focusableElements);
  var lastFocusableElement = focusableContent[focusableContent.length - 1];
  var shareViewButton = document.querySelectorAll(".action-bookmark")

  function onModalOpen() {
    document.addEventListener('keydown', function(e) {
        var isTabPressed = e.key === 'Tab';
      
        if (!isTabPressed) {
          return;
        }
      
        if (e.shiftKey) { 
          if (document.activeElement === firstFocusableElement) {
            lastFocusableElement.focus();
            e.preventDefault();
          }
        } else { 
          if (document.activeElement === lastFocusableElement) { 
            firstFocusableElement.focus(); 
            e.preventDefault();
          }
        }
      });
      
      firstFocusableElement.focus();
  }

  shareViewButton.forEach(button => {
    button.addEventListener("click", function (event) {
      event.preventDefault();
      onModalOpen();
    });
  });
})
