document.addEventListener("DOMContentLoaded", function () {
  var focusableElements = ".close, .trouble-shooting, .email-address, .btn"
  var modal = document.querySelector("#help-dialog")
  var firstFocusableElement = modal.querySelectorAll(focusableElements)[0]
  var secondFocusableElement = modal.querySelectorAll(focusableElements)[1]
  var focusableContent = modal.querySelectorAll(focusableElements)
  var lastFocusableElement = focusableContent[focusableContent.length - 1]
  var shareViewButton = document.querySelectorAll(".action-help")

  function onModalOpen() {
      setTimeout(function () {
          secondFocusableElement.focus()
        }, 10)
        document.addEventListener("keydown", function (e) {
            var isTabPressed = e.key === "Tab"
            
            if (!isTabPressed) {
                return
            }
            
            if (e.shiftKey) {
                if (document.activeElement === firstFocusableElement) {
                    lastFocusableElement.focus()
                    e.preventDefault()
                }
            } else {
                if (document.activeElement === lastFocusableElement) {
                    firstFocusableElement.focus()
                    e.preventDefault()
                }
            }
            console.log('modal open')
    })
  }

  shareViewButton.forEach(button => {
    button.addEventListener("click", function (event) {
      event.preventDefault();
      onModalOpen();
    });
  });
})
