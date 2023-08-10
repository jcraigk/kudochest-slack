//= require jquery

$(function () {
  let $left_btn = $('#leaderboard-page-left')
  let $right_btn = $('#leaderboard-page-right')

  $left_btn.on('click', function() {
    showSpinner($left_btn)
    shiftLeaderboardPage('left')
  })
  $right_btn.on('click', function() {
    showSpinner($right_btn)
    shiftLeaderboardPage()
  })

  function showSpinner($elem) {
    $elem.find('.main-icon').addClass('is-hidden')
    $elem.find('.spin-icon').removeClass('is-hidden')
  }

  function hideSpinners($elem) {
    [$left_btn, $right_btn].forEach(function($elem) {
      $elem.find('.spin-icon').addClass('is-hidden')
      $elem.find('.main-icon').removeClass('is-hidden')
    })
  }

  function shiftLeaderboardPage(dir) {
    const PER_PAGE = #{App.default_leaderboard_size}
    let offset = (dir == 'left' ? 0 - PER_PAGE : PER_PAGE)
    let new_offset = $('.rank-cell').first().data('rank') - 1 + offset
    if (new_offset < 0) new_offset = 0
    $.get(`/teams/leaderboard_page?offset=${new_offset}&count=${PER_PAGE}`, function(data) {
      if (data != '') $('#leaderboard-body').html(data)
      hideSpinners()
    })
  }
})
