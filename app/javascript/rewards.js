//= require jquery

$(function() {
  var $auto_fulfill = $('input[name="reward[auto_fulfill]"]')
  $auto_fulfill.on('click', function() { toggleInputs() })
  toggleInputs()

  function toggleInputs() {
    if ($auto_fulfill.is(':checked')) {
      $('#quantity-control').hide()
      $('#keys-control').show()
    } else {
      $('#quantity-control').show()
      $('#keys-control').hide()
    }
  }
})
