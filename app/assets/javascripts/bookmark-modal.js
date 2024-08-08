document.addEventListener("DOMContentLoaded",  function () {
  const focusableElements = 'input, .btn, .close'
  const modal = document.querySelector('#bookmark-dialog');
  const firstFocusableElement = modal.querySelectorAll(focusableElements)[0];
  const focusableContent = modal.querySelectorAll(focusableElements);
  const lastFocusableElement = focusableContent[focusableContent.length - 1];
  const shareViewButton = document.querySelector(".action-bookmark")

  function onModalOpen() {
    document.addEventListener('keydown', function(e) {
        let isTabPressed = e.key === 'Tab' || e.keyCode === 9;
      
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

  shareViewButton.addEventListener("click", function (event) {
    event.preventDefault()
    onModalOpen()
  })
})
