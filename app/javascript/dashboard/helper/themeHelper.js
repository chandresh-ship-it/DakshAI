import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { clearCustomThemeVariables, isDarkBackground } from './colorHelper';

export const setColorTheme = (isOSOnDarkMode, brandColors) => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // If we are moving away from custom, ensure inline custom backgrounds are cleared.
  // But skip clearing if BRAND_COLORS are injected by the server (custom domain branding).
  const hasDomainBranding =
    window.globalConfig && window.globalConfig.BRAND_COLORS;

  const activeBrandColors =
    brandColors ||
    (hasDomainBranding ? window.globalConfig.BRAND_COLORS : null);

  if (selectedColorScheme !== 'custom' && !hasDomainBranding) {
    clearCustomThemeVariables();
  }

  const isBrandDark =
    activeBrandColors &&
    activeBrandColors.background &&
    isDarkBackground(activeBrandColors.background);

  let isDark =
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark';

  if (
    selectedColorScheme === 'custom' ||
    (hasDomainBranding && selectedColorScheme === 'auto')
  ) {
    isDark = !!isBrandDark;
  }

  if (isDark) {
    document.body.classList.add('dark');
    document.documentElement.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
