module OnboardingHelper
  def join_all_channels_button(team, app_settings: false)
    link_to \
      icon_and_text('sign-in', t('onboarding.join_all_channels')),
      onboarding_join_all_channels_path(team, app_settings:),
      class: 'button is-primary',
      method: :patch
  end
end
