//= require jquery

$(function() {
  // Response Theme
  function showTheme(key) {
    $('.theme-info[data-name="' + key + '"]').show()
  }
  showTheme($('#team_response_theme').val())
  $('#team_response_theme').on('change', function() {
    $('.theme-info').hide()
    showTheme($(this).val())
  })

  // Level Curve
  function showSetting(key) {
    $('.setting-value[data-name="' + key + '"]').show()
  }
  showSetting($('#team_level_curve').val())
  $('#team_level_curve').on('change', function() {
    $('.setting-value').hide()
    showSetting($(this).val())
  })
})
