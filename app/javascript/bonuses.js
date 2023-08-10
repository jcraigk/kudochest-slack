//= require jquery

$().ready(function() {
  showInfo($('#bonus-calc-style').val())

  $('#bonus-calc-style').on('change', function() {
    $('.style-info').hide()
    $('.style-control').hide()
    showInfo($(this).val())
  })

  function showInfo(key) {
    $('.style-info[data-name="' + key + '"]').show()
    $('.style-control[data-name="' + key + '"]').show()
  }
})
