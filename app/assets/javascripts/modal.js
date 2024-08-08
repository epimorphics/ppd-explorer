document.addEventListener("DOMContentLoaded", function () {
    function handleModal(modalSelector, focusableElementsSelector, openButtonsSelector, focusOnOpenIndex = 0) {
      var modal = document.querySelector(modalSelector);
      var focusableElements = modal.querySelectorAll(focusableElementsSelector);
      var firstFocusableElement = focusableElements[0];
      var lastFocusableElement = focusableElements[focusableElements.length - 1];
      var focusOnOpenElement = focusableElements[focusOnOpenIndex];
      var openButtons = document.querySelectorAll(openButtonsSelector);
  
      function onModalOpen() {

        if(modalSelector === '#help-dialog') {
            setTimeout(function () {
              focusOnOpenElement.focus();
            }, 10);
        }
        
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
      }
  
      openButtons.forEach(function(button) {
        button.addEventListener("click", function (event) {
          event.preventDefault();
          onModalOpen();
        });
      });
    }
  
    handleModal('#bookmark-dialog', 'input, .btn, .close', '.action-bookmark');
  
    handleModal('#help-dialog', '.close, .trouble-shooting, .email-address, .btn', '.action-help', 1);
  });
  